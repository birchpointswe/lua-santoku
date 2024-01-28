#include "lua.h"
#include "lauxlib.h"

#include <stdlib.h>

int tk_string_base_number (lua_State *L)
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

luaL_Reg tk_string_mt_fns[] =
{
  { "number", tk_string_base_number },
  { NULL, NULL }
};

int luaopen_santoku_string_base (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_register(L, NULL, tk_string_mt_fns); // mt
  return 1;
}
