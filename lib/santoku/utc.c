#include "lua.h"
#include "lauxlib.h"

#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <time.h>

static inline void tk_lua_callmod (lua_State *L, int nargs, int nret, const char *smod, const char *sfn)
{
  lua_getglobal(L, "require"); // arg req
  lua_pushstring(L, smod); // arg req smod
  lua_call(L, 1, 1); // arg mod
  lua_pushstring(L, sfn); // args mod sfn
  lua_gettable(L, -2); // args mod fn
  lua_remove(L, -2); // args fn
  lua_insert(L, - nargs - 1); // fn args
  lua_call(L, nargs, nret); // results
}

static inline int tk_lua_errno (lua_State *L, int err)
{
  lua_pushstring(L, strerror(errno));
  lua_pushinteger(L, err);
  tk_lua_callmod(L, 2, 0, "santoku.error", "error");
  return 0;
}

static inline lua_Integer tk_lua_optfieldinteger (lua_State *L, int i, char *field, lua_Integer def)
{
  lua_getfield(L, i, field);
  lua_Integer n = luaL_optinteger(L, -1, def);
  lua_pop(L, 1);
  return n;
}

static inline lua_Integer tk_lua_checkfieldinteger (lua_State *L, int i, char *field)
{
  lua_getfield(L, i, field);
  lua_Integer n = luaL_checkinteger(L, -1);
  lua_pop(L, 1);
  return n;
}

static inline bool tk_lua_optboolean (lua_State *L, int i, bool def)
{
  if (lua_type(L, i) == LUA_TNIL)
    return def;
  luaL_checktype(L, i, LUA_TBOOLEAN);
  return lua_toboolean(L, i);
}

static inline bool tk_lua_optfieldboolean (lua_State *L, int i, char *field, bool def)
{
  lua_getfield(L, i, field);
  bool b = tk_lua_optboolean(L, -1, def);
  lua_pop(L, 1);
  return b;
}

static inline int tk_lua_absindex (lua_State *L, int i) {
  if (i < 0 && i > LUA_REGISTRYINDEX)
    i += lua_gettop(L) + 1;
  return i;
}

static inline bool tk_lua_streq (lua_State *L, int i, char *str)
{
  i = tk_lua_absindex(L, i);
  lua_pushstring(L, str);
  int r = lua_equal(L, i, -1);
  lua_pop(L, 1);
  return r == 1;
}

static inline unsigned int tk_lua_checkunsigned (lua_State *L, int i)
{
  lua_Integer l = luaL_checkinteger(L, i);
  if (l < 0)
    luaL_error(L, "value can't be negative");
  if (l > UINT_MAX)
    luaL_error(L, "value is too large");
  return (unsigned int) l;
}

static inline unsigned int tk_lua_optunsigned (lua_State *L, int i, unsigned int def)
{
  if (lua_type(L, i) < 1)
    return def;
  return tk_lua_checkunsigned(L, i);
}

static int utc_date (lua_State *L)
{

  time_t t;
  bool local;
  int n = lua_gettop(L);

  if (n == 1 && lua_type(L, 1) == LUA_TNUMBER) {
    t = lua_tointeger(L, 1);
    local = false;
    lua_settop(L, 0);
    lua_newtable(L);
  } else if (n == 1 && lua_type(L, 1) == LUA_TBOOLEAN) {
    t = time(NULL);
    local = lua_toboolean(L, 1);
    lua_settop(L, 0);
    lua_newtable(L);
  } else if (n == 2 && lua_type(L, 2) == LUA_TTABLE) {
    t = luaL_checkinteger(L, 1);
    local = false;
  } else {
    lua_settop(L, 3);
    t = luaL_checkinteger(L, 1);
    local = lua_toboolean(L, 2);
    if (lua_type(L, 3) == LUA_TNIL) {
      lua_pop(L, 1);
      lua_newtable(L);
    }
  }

  struct tm *info = local ? localtime(&t) : gmtime(&t);

  if (info == NULL)
    return tk_lua_errno(L, errno);

  lua_pushinteger(L, info->tm_year + 1900);
  lua_setfield(L, -2, "year");
  lua_pushinteger(L, info->tm_mon + 1);
  lua_setfield(L, -2, "month");
  lua_pushinteger(L, info->tm_mday);
  lua_setfield(L, -2, "day");
  lua_pushinteger(L, info->tm_wday + 1);
  lua_setfield(L, -2, "wday");
  lua_pushinteger(L, info->tm_yday + 1);
  lua_setfield(L, -2, "yday");
  lua_pushinteger(L, info->tm_hour);
  lua_setfield(L, -2, "hour");
  lua_pushinteger(L, info->tm_min);
  lua_setfield(L, -2, "min");
  lua_pushinteger(L, info->tm_sec);
  lua_setfield(L, -2, "sec");
  lua_pushboolean(L, info->tm_isdst > 0);
  lua_setfield(L, -2, "isdst");

  return 1;
}

static int utc_format (lua_State *L)
{
  lua_settop(L, 4);

  time_t t = luaL_checkinteger(L, 1);

  const char *fmt = luaL_checkstring(L, 2);

  bool local = lua_toboolean(L, 3);
  unsigned bufsize = tk_lua_optunsigned(L, 4, 1024);

  struct tm *info = local ? localtime(&t) : gmtime(&t);

  if (info == NULL)
    return tk_lua_errno(L, errno);

  char time[bufsize];

  size_t s = strftime(time, bufsize, fmt, info);

  lua_pushlstring(L, time, s);

  return 1;
}

static time_t utc_time_seconds ()
{
  return time(NULL);
}

static double utc_time_subsec (lua_State *L)
{
  struct timespec tp;
  if (clock_gettime(CLOCK_REALTIME, &tp))
    return tk_lua_errno(L, errno);
  return (double) tp.tv_sec + tp.tv_nsec / 1000000000.0;
}

static int utc_time (lua_State *L)
{
  lua_settop(L, 2);

  if (lua_type(L, 1) == LUA_TNIL) {
    if (lua_toboolean(L, 2))
      lua_pushnumber(L, utc_time_subsec(L));
    else
      lua_pushinteger(L, utc_time_seconds());
    return 1;
  } else if (lua_type(L, 1) == LUA_TBOOLEAN) {
    if (lua_toboolean(L, 1))
      lua_pushnumber(L, utc_time_subsec(L));
    else
      lua_pushinteger(L, utc_time_seconds());
    return 1;
  }

  luaL_checktype(L, 1, LUA_TTABLE);

  struct tm info = {
    .tm_year = tk_lua_checkfieldinteger(L, 1, "year") - 1900,
    .tm_mon = tk_lua_checkfieldinteger(L, 1, "month") - 1,
    .tm_mday = tk_lua_checkfieldinteger(L, 1, "day"),
    .tm_hour = tk_lua_optfieldinteger(L, 1, "hour", 0),
    .tm_min = tk_lua_optfieldinteger(L, 1, "min", 0),
    .tm_sec = tk_lua_optfieldinteger(L, 1, "sec", 0),
    .tm_isdst = tk_lua_optfieldboolean(L, 1, "isdst", 0) ? 1 : 0
  };

  time_t t = timegm(&info);

  if (t == (time_t)(-1))
    return tk_lua_errno(L, errno);

  lua_pushinteger(L, t);

  return 1;
}

static int utc_trunc (lua_State *L)
{
  if (lua_gettop(L) == 1) {
    const char *str = luaL_checkstring(L, 1);
    lua_settop(L, 0);
    utc_time(L);
    lua_pushstring(L, str);
  }

  time_t t = luaL_checkinteger(L, 1);

  luaL_checktype(L, 2, LUA_TSTRING);

  struct tm *info = gmtime(&t);

  if (info == NULL)
    return tk_lua_errno(L, errno);

  struct tm info0 = *info;

  if (tk_lua_streq(L, 2, "min")) {
    info0.tm_sec = 0;
  } else if (tk_lua_streq(L, 2, "hour")) {
    info0.tm_min = 0;
    info0.tm_sec = 0;
  } else if (tk_lua_streq(L, 2, "day")) {
    info0.tm_hour = 0;
    info0.tm_min = 0;
    info0.tm_sec = 0;
  } else if (tk_lua_streq(L, 2, "month")) {
    info0.tm_hour = 0;
    info0.tm_min = 0;
    info0.tm_sec = 0;
    info0.tm_mday = 1;
  } else if (tk_lua_streq(L, 2, "year")) {
    info0.tm_hour = 0;
    info0.tm_min = 0;
    info0.tm_sec = 0;
    info0.tm_mday = 1;
    info0.tm_mon = 1;
  }

  time_t t0 = timegm(&info0);
  if (t0 == (time_t)(-1))
    return tk_lua_errno(L, errno);

  if (lua_type(L, 3) == LUA_TTABLE) {
    lua_settop(L, 3);
    lua_insert(L, 1);
    lua_settop(L, 1);
    lua_pushinteger(L, t0);
    lua_insert(L, 1);
    utc_date(L);
  }

  lua_pushinteger(L, t0);
  return 1;
}

static int utc_shift (lua_State *L)
{
  lua_settop(L, 4);

  time_t t = luaL_checkinteger(L, 1);
  lua_Integer offset = luaL_checkinteger(L, 2);
  luaL_checktype(L, 3, LUA_TSTRING);

  struct tm *info = gmtime(&t);
  if (info == NULL)
    return tk_lua_errno(L, errno);

  struct tm info0 = *info;

  if (tk_lua_streq(L, 3, "sec")) {
    info0.tm_sec += offset;
  } else if (tk_lua_streq(L, 3, "min")) {
    info0.tm_min += offset;
  } else if (tk_lua_streq(L, 3, "hour")) {
    info0.tm_hour += offset;
  } else if (tk_lua_streq(L, 3, "day")) {
    info0.tm_mday += offset;
  } else if (tk_lua_streq(L, 3, "month")) {
    info0.tm_mon += offset;
  } else if (tk_lua_streq(L, 3, "year")) {
    info0.tm_year += offset;
  } else if (tk_lua_streq(L, 3, "dst")) {
    info0.tm_isdst = offset > 0 ? 1 : 0;
  }

  time_t t0 = timegm(&info0);
  if (t0 == (time_t)(-1))
    return tk_lua_errno(L, errno);

  if (lua_type(L, 4) == LUA_TTABLE) {
    lua_insert(L, 1);
    lua_settop(L, 1);
    lua_pushinteger(L, t0);
    lua_insert(L, 1);
    utc_date(L);
  }

  lua_pushinteger(L, t0);
  return 1;
}

static luaL_Reg fns[] =
{
  { "date", utc_date },
  { "time", utc_time },
  { "shift", utc_shift },
  { "trunc", utc_trunc },
  { "format", utc_format },
  { NULL, NULL }
};

int luaopen_santoku_utc (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_register(L, NULL, fns); // mt
  return 1;
}
