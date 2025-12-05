#include "lua.h"
#include "lauxlib.h"
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <santoku/lua/utils.h>

#define MAX_DEPTH_DEFAULT 200
#define INDENT_STRING "  "

#if !defined(LUA_VERSION_NUM) || LUA_VERSION_NUM < 502
#define lua_rawlen lua_objlen
#endif

static int lua_isinteger_compat(lua_State *L, int idx) {
#if LUA_VERSION_NUM >= 503
  return lua_isinteger(L, idx);
#else
  if (lua_type(L, idx) == LUA_TNUMBER) {
    lua_Number n = lua_tonumber(L, idx);
    if (isnan(n) || isinf(n)) {
      return 0;
    }
    return n == (lua_Number)(lua_Integer)n;
  }
  return 0;
#endif
}

static void serialize_value (
  lua_State *L,
  luaL_Buffer *buf,
  int idx,
  int level,
  const char *nl,
  const char *div,
  const char *sep,
  int seen_idx,
  int max_depth);

static void serialize_string (luaL_Buffer *buf, const char *s, size_t len) {
  luaL_addchar(buf, '"');
  for (size_t i = 0; i < len; i++) {
    unsigned char c = (unsigned char)s[i];
    switch (c) {
      case '"':  luaL_addstring(buf, "\\\""); break;
      case '\\': luaL_addstring(buf, "\\\\"); break;
      case '\n': luaL_addstring(buf, "\\n"); break;
      case '\r': luaL_addstring(buf, "\\r"); break;
      case '\t': luaL_addstring(buf, "\\t"); break;
      case '\0': luaL_addstring(buf, "\\000"); break;
      case '\a': luaL_addstring(buf, "\\a"); break;
      case '\b': luaL_addstring(buf, "\\b"); break;
      case '\f': luaL_addstring(buf, "\\f"); break;
      case '\v': luaL_addstring(buf, "\\v"); break;
      default:
        if (c < 32 || c >= 127) {
          char escape[5];
          snprintf(escape, sizeof(escape), "\\%03d", c);
          luaL_addstring(buf, escape);
        } else {
          luaL_addchar(buf, c);
        }
        break;
    }
  }
  luaL_addchar(buf, '"');
}

static void serialize_value (
  lua_State *L,
  luaL_Buffer *buf,
  int idx,
  int level,
  const char *nl,
  const char *div,
  const char *sep,
  int seen_idx,
  int max_depth
) {
  if (idx < 0 && idx > LUA_REGISTRYINDEX)
    idx = lua_gettop(L) + idx + 1;
  if (seen_idx < 0 && seen_idx > LUA_REGISTRYINDEX)
    seen_idx = lua_gettop(L) + seen_idx + 1;
  int type = lua_type(L, idx);
  switch (type) {

    case LUA_TNIL:
      luaL_addstring(buf, "nil");
      break;

    case LUA_TBOOLEAN:
      luaL_addstring(buf, lua_toboolean(L, idx) ? "true" : "false");
      break;

    case LUA_TNUMBER: {
      double num = lua_tonumber(L, idx);
      if (isnan(num)) {
        luaL_addstring(buf, "(0/0)");
      } else if (isinf(num)) {
        if (num > 0) {
          luaL_addstring(buf, "(1/0)");
        } else {
          luaL_addstring(buf, "(-1/0)");
        }
      } else if (lua_isinteger_compat(L, idx)) {
#if LUA_VERSION_NUM >= 503
        lua_pushfstring(L, "%I", lua_tointeger(L, idx));
        luaL_addvalue(buf);
#else
        char numbuf[64];
        snprintf(numbuf, sizeof(numbuf), "%.0f", num);
        luaL_addstring(buf, numbuf);
#endif
      } else {
        lua_pushnumber(L, num);
        luaL_addvalue(buf);
      }
      break;
    }

    case LUA_TSTRING: {
      size_t len;
      const char *s = lua_tolstring(L, idx, &len);
      serialize_string(buf, s, len);
      break;
    }

    case LUA_TTABLE: {

      if (level >= max_depth)
        luaL_error(L, "maximum serialization depth (%d) exceeded", max_depth);

      lua_pushvalue(L, idx);
      lua_gettable(L, seen_idx);
      if (!lua_isnil(L, -1)) {
        lua_pop(L, 1);
        luaL_addstring(buf, "nil");
        break;
      }

      lua_pop(L, 1);
      lua_pushvalue(L, idx);
      lua_pushboolean(L, 1);
      lua_settable(L, seen_idx);
      luaL_addchar(buf, '{');
      int nl_len = (nl[0] == '\0') ? 0 : 1;
      lua_Integer maxi = 0;
      lua_Integer n = (lua_Integer)lua_rawlen(L, idx);
      if (n > 100000000)
        luaL_error(L, "array part too large: %d", (int)n);
      for (lua_Integer i = 1; i <= n; i++) {
        lua_rawgeti(L, idx, i);
        if (lua_isnil(L, -1)) {
          lua_pop(L, 1);
          break;
        }
        maxi = i;
        lua_pop(L, 1);
      }

      int has_items = 0;
      for (lua_Integer i = 1; i <= maxi; i++) {
        if (nl_len > 0) {
          luaL_addchar(buf, '\n');
          for (int d = 0; d <= level; d++)
            luaL_addstring(buf, div);
        }
        int top = lua_gettop(L);
        lua_rawgeti(L, idx, i);
        serialize_value(L, buf, lua_gettop(L), level + 1, nl, div, sep, seen_idx, max_depth);
        lua_settop(L, top);
        if (i < maxi)
          luaL_addchar(buf, ',');
        has_items = 1;
      }

      int first_hash = (maxi == 0);
      lua_pushnil(L);

      while (lua_next(L, idx) != 0) {

        int skip = 0;
        if (lua_type(L, -2) == LUA_TNUMBER && lua_isinteger_compat(L, -2)) {
          lua_Integer k = lua_tointeger(L, -2);
          if (k >= 1 && k <= maxi)
            skip = 1;
        }

        int key_idx = lua_gettop(L) - 1;
        int val_idx = lua_gettop(L);

        if (!skip) {
          if (!first_hash && nl_len == 0)
            luaL_addchar(buf, ',');
          if (nl_len > 0) {
            if (!first_hash)
              luaL_addchar(buf, ',');
            luaL_addchar(buf, '\n');
            for (int d = 0; d <= level; d++)
              luaL_addstring(buf, div);
          }
          luaL_addchar(buf, '[');
          serialize_value(L, buf, key_idx, level + 1, nl, div, sep, seen_idx, max_depth);
          luaL_addchar(buf, ']');
          luaL_addstring(buf, sep);
          luaL_addchar(buf, '=');
          luaL_addstring(buf, sep);
          serialize_value(L, buf, val_idx, level + 1, nl, div, sep, seen_idx, max_depth);
          first_hash = 0;
          has_items = 1;
        }

        lua_pop(L, 1);
      }

      if (has_items && nl_len > 0) {
        luaL_addchar(buf, '\n');
        for (int d = 0; d < level; d++) {
          luaL_addstring(buf, div);
        }
      }

      luaL_addchar(buf, '}');
      lua_pushvalue(L, idx);
      lua_pushnil(L);
      lua_settable(L, seen_idx);

      break;
    }

    case LUA_TFUNCTION:
    case LUA_TUSERDATA:
    case LUA_TLIGHTUSERDATA:
    case LUA_TTHREAD:
      luaL_error(L, "cannot serialize %s", lua_typename(L, type));
      break;

    default:
      luaL_error(L, "unknown type: %s", lua_typename(L, type));
      break;

  }
}

static void serialize_table_contents (
  lua_State *L,
  luaL_Buffer *buf,
  int idx,
  int level,
  const char *nl,
  const char *div,
  const char *sep,
  int seen_idx,
  int max_depth
) {
  if (idx < 0 && idx > LUA_REGISTRYINDEX)
    idx = lua_gettop(L) + idx + 1;
  if (seen_idx < 0 && seen_idx > LUA_REGISTRYINDEX)
    seen_idx = lua_gettop(L) + seen_idx + 1;
  luaL_checktype(L, idx, LUA_TTABLE);

  lua_pushvalue(L, idx);
  lua_pushboolean(L, 1);
  lua_settable(L, seen_idx);

  int nl_len = (nl[0] == '\0') ? 0 : 1;

  lua_Integer maxi = 0;
  lua_Integer n = (lua_Integer)lua_rawlen(L, idx);
  if (n > 100000000)
    luaL_error(L, "array part too large: %d", (int)n);
  for (lua_Integer i = 1; i <= n; i++) {
    lua_rawgeti(L, idx, i);
    if (lua_isnil(L, -1)) {
      lua_pop(L, 1);
      break;
    }
    maxi = i;
    lua_pop(L, 1);
  }

  int has_items = 0;
  for (lua_Integer i = 1; i <= maxi; i++) {
    if (nl_len > 0) {
      luaL_addchar(buf, '\n');
      for (int d = 0; d < level; d++)
        luaL_addstring(buf, div);
    }
    int top = lua_gettop(L);
    lua_rawgeti(L, idx, i);
    serialize_value(L, buf, lua_gettop(L), level, nl, div, sep, seen_idx, max_depth);
    lua_settop(L, top);
    if (i < maxi)
      luaL_addchar(buf, ',');
    has_items = 1;
  }

  int first_hash = (maxi == 0);
  lua_pushnil(L);
  while (lua_next(L, idx) != 0) {
    int skip = 0;
    if (lua_type(L, -2) == LUA_TNUMBER && lua_isinteger_compat(L, -2)) {
      lua_Integer k = lua_tointeger(L, -2);
      if (k >= 1 && k <= maxi)
        skip = 1;
    }

    int key_idx = lua_gettop(L) - 1;
    int val_idx = lua_gettop(L);

    if (!skip) {
      if (!first_hash && nl_len == 0)
        luaL_addchar(buf, ',');
      if (nl_len > 0) {
        if (!first_hash)
          luaL_addchar(buf, ',');
        luaL_addchar(buf, '\n');
        for (int d = 0; d < level; d++)
          luaL_addstring(buf, div);
      }
      luaL_addchar(buf, '[');
      serialize_value(L, buf, key_idx, level, nl, div, sep, seen_idx, max_depth);
      luaL_addchar(buf, ']');
      luaL_addstring(buf, sep);
      luaL_addchar(buf, '=');
      luaL_addstring(buf, sep);
      serialize_value(L, buf, val_idx, level, nl, div, sep, seen_idx, max_depth);
      first_hash = 0;
      has_items = 1;
    }
    lua_pop(L, 1);
  }

  if (has_items && nl_len > 0) {
    luaL_addchar(buf, '\n');
    for (int d = 0; d < level - 1; d++)
      luaL_addstring(buf, div);
  }

  lua_pushvalue(L, idx);
  lua_pushnil(L);
  lua_settable(L, seen_idx);
}

static int santoku_serialize(lua_State *L) {
  int minify = 0;
  int seen_idx = 0;
  int max_depth = MAX_DEPTH_DEFAULT;
  if (lua_gettop(L) >= 2 && !lua_isnil(L, 2))
    minify = lua_toboolean(L, 2);
  if (lua_gettop(L) >= 3 && lua_istable(L, 3)) {
    seen_idx = 3;
  } else {
    lua_newtable(L);
    seen_idx = lua_gettop(L);
  }
  if (lua_gettop(L) >= 4 && lua_isnumber(L, 4)) {
    max_depth = lua_tointeger(L, 4);
    if (max_depth < 1) {
      return luaL_error(L, "max_depth must be at least 1");
    }
  }
  const char *nl = minify ? "" : "\n";
  const char *div = minify ? "" : INDENT_STRING;
  const char *sep = minify ? "" : " ";
  luaL_Buffer buf;
  luaL_buffinit(L, &buf);
  serialize_value(L, &buf, 1, 0, nl, div, sep, seen_idx, max_depth);
  luaL_pushresult(&buf);
  return 1;
}

static int santoku_serialize_table_contents(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  int minify = 0;
  int seen_idx = 0;
  int max_depth = MAX_DEPTH_DEFAULT;
  if (lua_gettop(L) >= 2 && !lua_isnil(L, 2)) {
    minify = lua_toboolean(L, 2);
  }
  if (lua_gettop(L) >= 3 && lua_istable(L, 3)) {
    seen_idx = 3;
  } else {
    lua_newtable(L);
    seen_idx = lua_gettop(L);
  }
  if (lua_gettop(L) >= 4 && lua_isnumber(L, 4)) {
    max_depth = lua_tointeger(L, 4);
    if (max_depth < 1)
      return luaL_error(L, "max_depth must be at least 1");
  }
  const char *nl = minify ? "" : "\n";
  const char *div = minify ? "" : INDENT_STRING;
  const char *sep = minify ? "" : " ";
  luaL_Buffer buf;
  luaL_buffinit(L, &buf);
  serialize_table_contents(L, &buf, 1, 1, nl, div, sep, seen_idx, max_depth);
  luaL_pushresult(&buf);
  return 1;
}

static int santoku_serialize_call (lua_State *L) {
  lua_remove(L, 1);
  return santoku_serialize(L);
}

static luaL_Reg fns[] = {
  { "serialize", santoku_serialize },
  { "serialize_table_contents", santoku_serialize_table_contents },
  { NULL, NULL }
};

int luaopen_santoku_serialize(lua_State *L) {
  lua_newtable(L);
  tk_lua_register(L, fns, 0);
  lua_newtable(L);
  lua_pushcfunction(L, santoku_serialize_call);
  lua_setfield(L, -2, "__call");
  lua_setmetatable(L, -2);
  return 1;
}
