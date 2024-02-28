#include "lua.h"
#include "lauxlib.h"

#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

static int tk_string_base_number (lua_State *L)
{
  lua_settop(L, 3);
  size_t len;
  const char *str = luaL_checklstring(L, 1, &len);
  lua_Integer s = luaL_checkinteger(L, 2) - 1;
  if (s > len)
    luaL_error(L, "string index out of bounds in number conversion");
  char *end;
  double val = strtod(str + s, &end);
  if (str != end) {
    lua_pushnumber(L, val);
    return 1;
  } else {
    return 0;
  }
}

static int tk_string_base_equals (lua_State *L)
{
  lua_settop(L, 4);
  size_t litlen;
  const char *lit = luaL_checklstring(L, 1, &litlen);
  size_t chunklen;
  const char *chunk = luaL_checklstring(L, 2, &chunklen);
  lua_Integer s = luaL_checkinteger(L, 3);
  if (s < 1) {
    lua_pushboolean(L, false);
    return 1;
  }
  if (s > chunklen) {
    lua_pushboolean(L, false);
    return 1;
  }
  lua_Integer e = luaL_checkinteger(L, 4);
  if (e < 1) {
    lua_pushboolean(L, false);
    return 1;
  }
  lua_pushboolean(L, strncmp(lit, chunk + s - 1, e - s + 1) == 0);
  return 1;
}

static luaL_Reg tk_string_mt_fns[] =
{
  { "number", tk_string_base_number },
  { "equals", tk_string_base_equals },
  { NULL, NULL }
};

int luaopen_santoku_string_base (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_register(L, NULL, tk_string_mt_fns); // mt
  return 1;
}
