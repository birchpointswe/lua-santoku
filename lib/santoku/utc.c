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

static inline lua_Integer tk_lua_checkfieldinteger (lua_State *L, int i, char *field)
{
  lua_getfield(L, i, field);
  lua_Integer n = luaL_checkinteger(L, -1);
  lua_pop(L, 1);
  return n;
}

static inline bool tk_lua_checkfieldboolean (lua_State *L, int i, char *field)
{
  lua_getfield(L, i, field);
  luaL_checktype(L, -1, LUA_TBOOLEAN);
  bool n = lua_toboolean(L, -1);
  lua_pop(L, 1);
  return n;
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
  lua_settop(L, 2);

  time_t t;
  bool local;

  if (lua_type(L, 1) == LUA_TNUMBER) {
    t = luaL_checkinteger(L, 1);
    local = lua_toboolean(L, 2);
  } else if (lua_type(L, 1) == LUA_TBOOLEAN) {
    t = time(NULL);
    local = lua_toboolean(L, 1);
  } else {
    luaL_checktype(L, 1, LUA_TNUMBER);
    luaL_checktype(L, 2, LUA_TBOOLEAN);
    return 0;
  }

  struct tm *info = local ? localtime(&t) : gmtime(&t);

  if (info == NULL)
    return tk_lua_errno(L, errno);

  lua_newtable(L);

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

static int utc_time (lua_State *L)
{
  lua_settop(L, 1);

  if (lua_type(L, 1) == LUA_TNIL) {
    lua_pushinteger(L, time(NULL));
    return 1;
  }

  luaL_checktype(L, 1, LUA_TTABLE);

  struct tm info = {
    .tm_year = tk_lua_checkfieldinteger(L, 1, "year") - 1900,
    .tm_mon = tk_lua_checkfieldinteger(L, 1, "month") - 1,
    .tm_mday = tk_lua_checkfieldinteger(L, 1, "day"),
    .tm_hour = tk_lua_checkfieldinteger(L, 1, "hour"),
    .tm_min = tk_lua_checkfieldinteger(L, 1, "min"),
    .tm_sec = tk_lua_checkfieldinteger(L, 1, "sec"),
    .tm_isdst = tk_lua_checkfieldboolean(L, 1, "isdst") ? 1 : 0
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

  lua_pushinteger(L, t0);

  return 1;
}

static int utc_shift (lua_State *L)
{
  lua_settop(L, 3);

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

  lua_pushinteger(L, t0);
  return 1;
}

static luaL_Reg fns[] =
{
  { "date", utc_date }, // utc timestamp -> date table, utc or local
  { "time", utc_time }, // date table, utc or local -> utc timestamp
  { "shift", utc_shift }, // utc timestamp -> utc timestamp
  { "trunc", utc_trunc }, // utc timestamp -> utc timestamp
  { "format", utc_format }, // utc timestamp -> string, utc or local
  { NULL, NULL }
};

int luaopen_santoku_utc (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_register(L, NULL, fns); // mt
  return 1;
}
