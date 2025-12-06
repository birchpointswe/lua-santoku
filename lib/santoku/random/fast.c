#include <santoku/lua/utils.h>

static inline int fast_seed (lua_State *L)
{
  tk_fast_seed(tk_lua_optunsigned(L, 1, "seed", time(NULL)));
  return 0;
}

static inline int fast_random (lua_State *L)
{
  lua_pushinteger(L, (lua_Integer)tk_fast_random());
  return 1;
}

static inline int fast_normal (lua_State *L)
{
  double mean = luaL_checknumber(L, 1);
  double variance = luaL_checknumber(L, 2);
  double normal = tk_fast_normal(mean, variance);
  lua_pushnumber(L, normal);
  return 1;
}


static luaL_Reg fns[] = {
  { "fast_seed", fast_seed },
  { "fast_random", fast_random },
  { "fast_normal", fast_normal },
  { NULL, NULL }
};

int luaopen_santoku_random_fast (lua_State *L)
{
  lua_newtable(L);
  luaL_register(L, NULL, fns);
  lua_pushinteger(L, (lua_Integer)UINT32_MAX);
  lua_setfield(L, -2, "fast_max");
  return 1;
}
