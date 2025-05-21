#include <santoku/lua/utils.h>

int luaopen_santoku_validate_capi (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_getmetatable(L, LUA_FILEHANDLE); // mt fh
  lua_setfield(L, -2, "MT_FILEHANDLE"); // mt
  return 1;
}
