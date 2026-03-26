#include <santoku/lua/utils.h>

#ifdef __GLIBC__
#include <malloc.h>
#endif

static inline int tk_lua_mt_userdata (lua_State *L)
{
  luaL_checktype(L, -1, LUA_TTABLE);
  lua_newuserdata(L, 0);
  lua_insert(L, -2);
  lua_setmetatable(L, -2);
  return 1;
}

static inline int tk_lua_malloc_trim (lua_State *L)
{
  (void)L;
#ifdef __GLIBC__
  malloc_trim(0);
#endif
  return 0;
}

luaL_Reg tk_lua_mt_fns[] =
{
  { "userdata", tk_lua_mt_userdata },
  { "malloc_trim", tk_lua_malloc_trim },
  { NULL, NULL }
};

int luaopen_santoku_lua_lua (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_register(L, NULL, tk_lua_mt_fns); // mt
  return 1;
}
