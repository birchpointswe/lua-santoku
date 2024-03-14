#include "lua.h"
#include "lauxlib.h"

#include <stdint.h>
#include <math.h>

static uint64_t const multiplier = 6364136223846793005u;
static uint64_t mcg_state = 0xcafef00dd15ea5e5u;

static inline uint32_t _fast_random ()
{
  uint64_t x = mcg_state;
  unsigned int count = (unsigned int) (x >> 61);
  mcg_state = x * multiplier;
  return (uint32_t) ((x ^ x >> 22) >> (22 + count));
}

static inline int _fast_normal (double mean, double variance)
{
  double u1 = (double) (_fast_random() + 1) / ((double) UINT32_MAX + 1);
  double u2 = (double) _fast_random() / UINT32_MAX;
  double n1 = sqrt(-2 * log(u1)) * sin(8 * atan(1) * u2);
  return round(mean + sqrt(variance) * n1);
}

static inline int fast_random (lua_State *L)
{
  lua_pushinteger(L, _fast_random());
  return 1;
}

static inline int fast_normal (lua_State *L)
{
  double mean = luaL_checknumber(L, 1);
  double variance = luaL_checknumber(L, 2);
  double normal = _fast_normal(mean, variance);
  lua_pushnumber(L, normal);
  return 1;
}


static luaL_Reg fns[] = {
  { "fast_random", fast_random },
  { "fast_normal", fast_normal },
  { NULL, NULL }
};

int luaopen_santoku_random_fast (lua_State *L)
{
  lua_newtable(L);
  luaL_register(L, NULL, fns);
  lua_pushinteger(L, UINT32_MAX);
  lua_setfield(L, -2, "fast_max");
  return 1;
}
