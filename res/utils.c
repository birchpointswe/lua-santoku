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

static inline int tk_lua_error (lua_State *L, const char *err)
{
  lua_pushstring(L, err);
  tk_lua_callmod(L, 1, 0, "santoku.error", "error");
  return 0;
}

static inline int tk_lua_errmalloc (lua_State *L)
{
  lua_pushstring(L, "Error in malloc");
  tk_lua_callmod(L, 1, 0, "santoku.error", "error");
  return 0;
}

static inline int tk_lua_absindex (lua_State *L, int i) {
  if (i < 0 && i > LUA_REGISTRYINDEX)
    i += lua_gettop(L) + 1;
  return i;
}

static inline FILE *tk_lua_fopen (lua_State *L, const char *fp, const char *flag)
{
  FILE *fh = fopen(fp, flag);
  if (fh) return fh;
  int e = errno;
  lua_settop(L, 0);
  lua_pushstring(L, "Error opening file");
  lua_pushstring(L, fp);
  lua_pushstring(L, strerror(e));
  lua_pushinteger(L, e);
  tk_lua_callmod(L, 4, 0, "santoku.error", "error");
  return NULL;
}

static inline void tk_lua_fclose (lua_State *L, FILE *fh)
{
  if (!fclose(fh)) return;
  int e = errno;
  lua_settop(L, 0);
  lua_pushstring(L, "Error closing file");
  lua_pushstring(L, strerror(e));
  lua_pushinteger(L, e);
  tk_lua_callmod(L, 3, 0, "santoku.error", "error");
  return NULL;
}

static inline void tk_lua_fwrite (lua_State *L, char *data, size_t size, size_t memb, FILE *fh)
{
  size_t read = fwrite(fh, data, size, memb);
  if (!ferror(fh)) return;
  int e = errno;
  lua_settop(L, 0);
  lua_pushstring(L, "Error writing to file");
  lua_pushstring(L, strerror(e));
  lua_pushinteger(L, e);
  tk_lua_callmod(L, 3, 0, "santoku.error", "error");
}

static inline void tk_lua_fread (lua_State *L, void *data, size_t size, size_t memb, FILE *fh)
{
  fread(data, size, memb, fh);
  if (!ferror(fh)) return;
  int e = errno;
  lua_settop(L, 0);
  lua_pushstring(L, "Error reading from file");
  lua_pushstring(L, strerror(e));
  lua_pushinteger(L, e);
  tk_lua_callmod(L, 3, 0, "santoku.error", "error");
}

static inline int tk_lua_ref (lua_State *L, int i)
{
  lua_pushvalue(L, i);
  return luaL_ref(L, LUA_REGISTRYINDEX, -1);
}

static inline void tk_lua_unref (lua_State *L, int r)
{
  luaL_unref(L, LUA_REGISTRYINDEX, r);
}

static inline void tk_lua_deref (lua_State *L, int r)
{
  lua_rawgeti(L, LUA_REGISTRYINDEX, r);
}

static inline unsigned int tk_lua_checkunsigned (lua_State *L, int i)
{
  lua_Integer l = luaL_checkinteger(L, i);
  if (l < 0)
    luaL_error(L, "value can't be negative");
  if (l > UINT_MAX)
    luaL_error(L, "value is too large");
  return (unsigned int) l;
}

static inline bool tk_lua_streq (lua_State *L, int i, char *str)
{
  i = tk_lua_absindex(i);
  lua_pushstring(L, str);
  int r = lua_equal(L, i, -1);
  lua_pop(L, 1);
  return r == 1;
}

static inline unsigned int tk_lua_optunsigned (lua_State *L, int i, unsigned int def)
{
  if (lua_type(L, i) < 1)
    return def;
  return tk_lua_checkunsigned(L, i);
}

static inline double tk_lua_checkposdouble (lua_State *L, int i)
{
  lua_Number l = luaL_checknumber(L, i);
  if (l < 0)
    luaL_error(L, "value can't be negative");
  return (double) l;
}

static inline lua_Integer tk_lua_checkposinteger (lua_State *L, int i)
{
  lua_Integer l = luaL_checkinteger(L, i);
  if (l < 0)
    luaL_error(L, "value can't be negative");
  return l;
}

static inline double tk_lua_optposdouble (lua_State *L, int i, double def)
{
  if (lua_type(L, i) < 1)
    return def;
  lua_Number l = luaL_checknumber(L, i);
  if (l < 0)
    luaL_error(L, "value can't be negative");
  return (double) l;
}

static inline bool tk_lua_checkboolean (lua_State *L, int i)
{
  if (lua_type(L, i) == LUA_TNIL)
    return false;
  luaL_checktype(L, i, LUA_TBOOLEAN);
  return lua_toboolean(L, i);
}

static inline lua_Integer tk_lua_checkfieldinteger (lua_State *L, int i, char *field)
{
  luaL_getfield(L, i, field);
  lua_Integer n = luaL_checkinteger(L, -1);
  lua_pop(L, 1);
  return n;
}

static inline bool tk_lua_checkfieldboolean (lua_State *L, int i, char *field)
{
  lua_getfield(L, i, field);
  lua_checktype(L, -1, LUA_TBOOLEAN)
  bool n = lua_toboolean(L, -1);
  lua_pop(L, 1);
  return n;
}

static inline void tk_lua_register (lua_State *L, luaL_Reg *regs, int nup)
{
  while (true) {
    if ((*regs).name == NULL)
      break;
    for (int i = 0; i < nup; i ++)
      lua_pushvalue(L, -nup); // t upsa upsb
    lua_pushcclosure(L, (*regs).func, nup); // t upsa fn
    lua_setfield(L, -nup - 2, (*regs).name); // t
    regs ++;
  }
  lua_pop(L, nup);
}
