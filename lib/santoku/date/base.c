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

static int utc_trunc (lua_State *L)
{
  lua_settop(L, 2);

  luaL_checktype(L, 1, LUA_TTABLE);
  luaL_checktype(L, 2, LUA_TSTRING);

  struct tm info = {
    .tm_year = tk_lua_checkfieldinteger(L, 1, "year") - 1900,
    .tm_mon = tk_lua_checkfieldinteger(L, 1, "month") - 1,
    .tm_mday = tk_lua_checkfieldinteger(L, 1, "day"),
    .tm_hour = tk_lua_checkfieldinteger(L, 1, "hour"),
    .tm_min = tk_lua_checkfieldinteger(L, 1, "min"),
    .tm_sec = tk_lua_checkfieldinteger(L, 1, "sec"),
    .tm_isdst = tk_lua_checkfieldboolean(L, 1, "isdst") ? 1 : 0
  };

  if (tk_lua_streq(L, 2, "min")) {
    info.tm_sec = 0;
  } else if (tk_lua_streq(L, 2, "hour")) {
    info.tm_min = 0;
    info.tm_sec = 0;
  } else if (tk_lua_streq(L, 2, "day")) {
    info.tm_hour = 0;
    info.tm_min = 0;
    info.tm_sec = 0;
  } else if (tk_lua_streq(L, 2, "month")) {
    info.tm_hour = 0;
    info.tm_min = 0;
    info.tm_sec = 0;
    info.tm_mday = 0;
  } else if (tk_lua_streq(L, 2, "year")) {
    info.tm_hour = 0;
    info.tm_min = 0;
    info.tm_sec = 0;
    info.tm_mday = 0;
    info.tm_mon = 1;
  }

  time_t t = timegm(&info);
  struct tm *info0 = gmtime(&t);

  lua_pushinteger(L, info0->tm_year + 1900);
  lua_setfield(L, 1, "year");
  lua_pushinteger(L, info0->tm_mon + 1);
  lua_setfield(L, 1, "month");
  lua_pushinteger(L, info0->tm_mday);
  lua_setfield(L, 1, "day");
  lua_pushinteger(L, info0->tm_hour);
  lua_setfield(L, 1, "hour");
  lua_pushinteger(L, info0->tm_min);
  lua_setfield(L, 1, "min");
  lua_pushinteger(L, info0->tm_sec);
  lua_setfield(L, 1, "sec");
  lua_pushboolean(L, info0->tm_isdst > 0);
  lua_setfield(L, 1, "isdst");

  lua_pushinteger(L, t);
  lua_pushvalue(L, 1);

  return 2;
}

static int utc_shift (lua_State *L)
{
  lua_settop(L, 3);

  luaL_checktype(L, 1, LUA_TTABLE);
  lua_Integer n = luaL_checkinteger(L, 2);
  luaL_checktype(L, 3, LUA_TSTRING);

  struct tm info = {
    .tm_year = tk_lua_checkfieldinteger(L, 1, "year") - 1900,
    .tm_mon = tk_lua_checkfieldinteger(L, 1, "month") - 1,
    .tm_mday = tk_lua_checkfieldinteger(L, 1, "day"),
    .tm_hour = tk_lua_checkfieldinteger(L, 1, "hour"),
    .tm_min = tk_lua_checkfieldinteger(L, 1, "min"),
    .tm_sec = tk_lua_checkfieldinteger(L, 1, "sec"),
    .tm_isdst = tk_lua_checkfieldboolean(L, 1, "isdst") ? 1 : 0
  };

  if (tk_lua_streq(L, 3, "sec")) {
    info.tm_sec += n;
  } else if (tk_lua_streq(L, 3, "min")) {
    info.tm_min += n;
  } else if (tk_lua_streq(L, 3, "hour")) {
    info.tm_hour += n;
  } else if (tk_lua_streq(L, 3, "day")) {
    info.tm_mday += n;
  } else if (tk_lua_streq(L, 3, "month")) {
    info.tm_mon += n;
  } else if (tk_lua_streq(L, 3, "year")) {
    info.tm_year += n;
  } else if (tk_lua_streq(L, 3, "dst")) {
    info.tm_isdst = n > 0 ? 1 : 0;
  }

  time_t t = timegm(&info);
  struct tm *info0 = gmtime(&t);

  lua_pushinteger(L, info0->tm_year + 1900);
  lua_setfield(L, 1, "year");
  lua_pushinteger(L, info0->tm_mon + 1);
  lua_setfield(L, 1, "month");
  lua_pushinteger(L, info0->tm_mday);
  lua_setfield(L, 1, "day");
  lua_pushinteger(L, info0->tm_hour);
  lua_setfield(L, 1, "hour");
  lua_pushinteger(L, info0->tm_min);
  lua_setfield(L, 1, "min");
  lua_pushinteger(L, info0->tm_sec);
  lua_setfield(L, 1, "sec");
  lua_pushboolean(L, info0->tm_isdst > 0);
  lua_setfield(L, 1, "isdst");

  lua_pushinteger(L, t);
  lua_pushvalue(L, 1);

  return 2;
}

static int utc_date (lua_State *L)
{
  time_t t;

  if (lua_gettop(L) == 0) {
    t = time(NULL);
  } else {
    t = luaL_checkinteger(L, 1);
  }

  struct tm *info = gmtime(&t);

  if (info == NULL)
    return tk_lua_errno(L, errno);

  lua_newtable(L);
  lua_pushinteger(L, info->tm_year + 1900);
  lua_setfield(L, -2, "year");
  lua_pushinteger(L, info->tm_mon + 1);
  lua_setfield(L, -2, "month");
  lua_pushinteger(L, info->tm_mday);
  lua_setfield(L, -2, "day");
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

static int utc_local (lua_State *L)
{
  time_t t;

  if (lua_gettop(L) == 0) {
    t = time(NULL);
  } else {
    t = luaL_checkinteger(L, 1);
  }

  struct tm *info = localtime(&t);

  if (info == NULL)
    return tk_lua_errno(L, errno);

  lua_newtable(L);
  lua_pushinteger(L, info->tm_year + 1900);
  lua_setfield(L, -2, "year");
  lua_pushinteger(L, info->tm_mon + 1);
  lua_setfield(L, -2, "month");
  lua_pushinteger(L, info->tm_mday);
  lua_setfield(L, -2, "day");
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

static luaL_Reg fns[] =
{
  { "utc_shift", utc_shift },
  { "utc_trunc", utc_trunc },
  { "utc_date", utc_date },
  { "utc_local", utc_local },
  { "utc_time", utc_time },
  { NULL, NULL }
};

int luaopen_santoku_date_base (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_register(L, NULL, fns); // mt
  return 1;
}
