#include <santoku/lua/utils.h>
#include <time.h>

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

  time_t t = tk_lua_checkinteger(L, 1, "time");
  const char *fmt = tk_lua_checkstring(L, 2, "format");
  bool local = tk_lua_optboolean(L, 3, "local", false);
  unsigned bufsize = tk_lua_optunsigned(L, 4, "bufsize", 1024);

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
    .tm_year = tk_lua_fcheckinteger(L, 1, "time", "year") - 1900,
    .tm_mon = tk_lua_fcheckinteger(L, 1, "time", "month") - 1,
    .tm_mday = tk_lua_fcheckinteger(L, 1, "time", "day"),
    .tm_hour = tk_lua_foptinteger(L, 1, "time", "hour", 0),
    .tm_min = tk_lua_foptinteger(L, 1, "time", "min", 0),
    .tm_sec = tk_lua_foptinteger(L, 1, "time", "sec", 0),
    .tm_isdst = tk_lua_foptboolean(L, 1, "time", "isdst", 0) ? 1 : 0
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

int luaopen_santoku_utc_capi (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_register(L, NULL, fns); // mt
  return 1;
}
