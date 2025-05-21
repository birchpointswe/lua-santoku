#include <santoku/lua/utils.h>

static inline int tk_lua_mt_userdata (lua_State *L)
{
  luaL_checktype(L, -1, LUA_TTABLE);
  lua_newuserdata(L, 0);
  lua_insert(L, -2);
  lua_setmetatable(L, -2);
  return 1;
}

luaL_Reg tk_lua_mt_fns[] =
{
  { "userdata", tk_lua_mt_userdata },
  { NULL, NULL }
};

int luaopen_santoku_lua_lua (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_register(L, NULL, tk_lua_mt_fns); // mt
  return 1;
}
