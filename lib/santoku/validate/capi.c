// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2023 Birch Point SWE
#include <santoku/lua/utils.h>

int luaopen_santoku_validate_capi (lua_State *L)
{
  lua_newtable(L);
  luaL_getmetatable(L, LUA_FILEHANDLE);
  lua_setfield(L, -2, "MT_FILEHANDLE");
  return 1;
}
