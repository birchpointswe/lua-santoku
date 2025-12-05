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

static void out_push(lua_State *L, int out_idx, lua_Integer *n, const char *s) {
  lua_pushstring(L, s);
  lua_rawseti(L, out_idx, ++(*n));
}

static void out_pushlen(lua_State *L, int out_idx, lua_Integer *n, const char *s, size_t len) {
  lua_pushlstring(L, s, len);
  lua_rawseti(L, out_idx, ++(*n));
}

static void out_pushchar(lua_State *L, int out_idx, lua_Integer *n, char c) {
  lua_pushlstring(L, &c, 1);
  lua_rawseti(L, out_idx, ++(*n));
}

static void out_pushvalue(lua_State *L, int out_idx, lua_Integer *n) {
  lua_rawseti(L, out_idx, ++(*n));
}

static void serialize_value(
  lua_State *L,
  int out_idx,
  lua_Integer *out_n,
  int idx,
  int level,
  const char *nl,
  const char *div,
  const char *sep,
  int seen_idx,
  int max_depth);

static void serialize_string(lua_State *L, int out_idx, lua_Integer *out_n, const char *s, size_t len) {
  out_pushchar(L, out_idx, out_n, '"');
  size_t start = 0;
  for (size_t i = 0; i < len; i++) {
    unsigned char c = (unsigned char)s[i];
    const char *esc = NULL;
    char escbuf[5];
    switch (c) {
      case '"':  esc = "\\\""; break;
      case '\\': esc = "\\\\"; break;
      case '\n': esc = "\\n"; break;
      case '\r': esc = "\\r"; break;
      case '\t': esc = "\\t"; break;
      case '\0': esc = "\\000"; break;
      case '\a': esc = "\\a"; break;
      case '\b': esc = "\\b"; break;
      case '\f': esc = "\\f"; break;
      case '\v': esc = "\\v"; break;
      default:
        if (c < 32 || c >= 127) {
          snprintf(escbuf, sizeof(escbuf), "\\%03d", c);
          esc = escbuf;
        }
        break;
    }
    if (esc) {
      if (i > start)
        out_pushlen(L, out_idx, out_n, s + start, i - start);
      out_push(L, out_idx, out_n, esc);
      start = i + 1;
    }
  }
  if (len > start)
    out_pushlen(L, out_idx, out_n, s + start, len - start);
  out_pushchar(L, out_idx, out_n, '"');
}

static void serialize_value(
  lua_State *L,
  int out_idx,
  lua_Integer *out_n,
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
      out_push(L, out_idx, out_n, "nil");
      break;

    case LUA_TBOOLEAN:
      out_push(L, out_idx, out_n, lua_toboolean(L, idx) ? "true" : "false");
      break;

    case LUA_TNUMBER: {
      double num = lua_tonumber(L, idx);
      if (isnan(num)) {
        out_push(L, out_idx, out_n, "(0/0)");
      } else if (isinf(num)) {
        out_push(L, out_idx, out_n, num > 0 ? "(1/0)" : "(-1/0)");
      } else if (lua_isinteger_compat(L, idx)) {
#if LUA_VERSION_NUM >= 503
        lua_pushfstring(L, "%I", lua_tointeger(L, idx));
        out_pushvalue(L, out_idx, out_n);
#else
        char numbuf[64];
        snprintf(numbuf, sizeof(numbuf), "%.0f", num);
        out_push(L, out_idx, out_n, numbuf);
#endif
      } else {
        lua_pushnumber(L, num);
        lua_tostring(L, -1);
        out_pushvalue(L, out_idx, out_n);
      }
      break;
    }

    case LUA_TSTRING: {
      size_t len;
      const char *s = lua_tolstring(L, idx, &len);
      serialize_string(L, out_idx, out_n, s, len);
      break;
    }

    case LUA_TTABLE: {
      if (level >= max_depth)
        luaL_error(L, "maximum serialization depth (%d) exceeded", max_depth);

      lua_pushvalue(L, idx);
      lua_gettable(L, seen_idx);
      if (!lua_isnil(L, -1)) {
        lua_pop(L, 1);
        out_push(L, out_idx, out_n, "nil");
        break;
      }
      lua_pop(L, 1);

      lua_pushvalue(L, idx);
      lua_pushboolean(L, 1);
      lua_settable(L, seen_idx);

      out_pushchar(L, out_idx, out_n, '{');
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
          out_pushchar(L, out_idx, out_n, '\n');
          for (int d = 0; d <= level; d++)
            out_push(L, out_idx, out_n, div);
        }
        int top = lua_gettop(L);
        lua_rawgeti(L, idx, i);
        serialize_value(L, out_idx, out_n, -1, level + 1, nl, div, sep, seen_idx, max_depth);
        lua_settop(L, top);
        if (i < maxi)
          out_pushchar(L, out_idx, out_n, ',');
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
        if (!skip) {
          if (!first_hash && nl_len == 0)
            out_pushchar(L, out_idx, out_n, ',');
          if (nl_len > 0) {
            if (!first_hash)
              out_pushchar(L, out_idx, out_n, ',');
            out_pushchar(L, out_idx, out_n, '\n');
            for (int d = 0; d <= level; d++)
              out_push(L, out_idx, out_n, div);
          }
          out_pushchar(L, out_idx, out_n, '[');
          serialize_value(L, out_idx, out_n, -2, level + 1, nl, div, sep, seen_idx, max_depth);
          out_pushchar(L, out_idx, out_n, ']');
          out_push(L, out_idx, out_n, sep);
          out_pushchar(L, out_idx, out_n, '=');
          out_push(L, out_idx, out_n, sep);
          serialize_value(L, out_idx, out_n, -1, level + 1, nl, div, sep, seen_idx, max_depth);
          first_hash = 0;
          has_items = 1;
        }
        lua_pop(L, 1);
      }

      if (has_items && nl_len > 0) {
        out_pushchar(L, out_idx, out_n, '\n');
        for (int d = 0; d < level; d++)
          out_push(L, out_idx, out_n, div);
      }

      out_pushchar(L, out_idx, out_n, '}');

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

static void serialize_table_contents(
  lua_State *L,
  int out_idx,
  lua_Integer *out_n,
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
      out_pushchar(L, out_idx, out_n, '\n');
      for (int d = 0; d < level; d++)
        out_push(L, out_idx, out_n, div);
    }
    int top = lua_gettop(L);
    lua_rawgeti(L, idx, i);
    serialize_value(L, out_idx, out_n, -1, level, nl, div, sep, seen_idx, max_depth);
    lua_settop(L, top);
    if (i < maxi)
      out_pushchar(L, out_idx, out_n, ',');
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
    if (!skip) {
      if (!first_hash && nl_len == 0)
        out_pushchar(L, out_idx, out_n, ',');
      if (nl_len > 0) {
        if (!first_hash)
          out_pushchar(L, out_idx, out_n, ',');
        out_pushchar(L, out_idx, out_n, '\n');
        for (int d = 0; d < level; d++)
          out_push(L, out_idx, out_n, div);
      }
      out_pushchar(L, out_idx, out_n, '[');
      serialize_value(L, out_idx, out_n, -2, level, nl, div, sep, seen_idx, max_depth);
      out_pushchar(L, out_idx, out_n, ']');
      out_push(L, out_idx, out_n, sep);
      out_pushchar(L, out_idx, out_n, '=');
      out_push(L, out_idx, out_n, sep);
      serialize_value(L, out_idx, out_n, -1, level, nl, div, sep, seen_idx, max_depth);
      first_hash = 0;
      has_items = 1;
    }
    lua_pop(L, 1);
  }

  if (has_items && nl_len > 0) {
    out_pushchar(L, out_idx, out_n, '\n');
    for (int d = 0; d < level - 1; d++)
      out_push(L, out_idx, out_n, div);
  }

  lua_pushvalue(L, idx);
  lua_pushnil(L);
  lua_settable(L, seen_idx);
}

static void concat_out(lua_State *L, int out_idx) {
  lua_getglobal(L, "table");
  lua_getfield(L, -1, "concat");
  lua_remove(L, -2);
  lua_pushvalue(L, out_idx);
  lua_call(L, 1, 1);
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
    if (max_depth < 1)
      return luaL_error(L, "max_depth must be at least 1");
  }
  const char *nl = minify ? "" : "\n";
  const char *div = minify ? "" : INDENT_STRING;
  const char *sep = minify ? "" : " ";

  lua_newtable(L);
  int out_idx = lua_gettop(L);
  lua_Integer out_n = 0;

  serialize_value(L, out_idx, &out_n, 1, 0, nl, div, sep, seen_idx, max_depth);
  concat_out(L, out_idx);
  return 1;
}

static int santoku_serialize_table_contents(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
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
    if (max_depth < 1)
      return luaL_error(L, "max_depth must be at least 1");
  }
  const char *nl = minify ? "" : "\n";
  const char *div = minify ? "" : INDENT_STRING;
  const char *sep = minify ? "" : " ";

  lua_newtable(L);
  int out_idx = lua_gettop(L);
  lua_Integer out_n = 0;

  serialize_table_contents(L, out_idx, &out_n, 1, 1, nl, div, sep, seen_idx, max_depth);
  concat_out(L, out_idx);
  return 1;
}

static int santoku_serialize_call(lua_State *L) {
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
