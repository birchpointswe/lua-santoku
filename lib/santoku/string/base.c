// TODO: Expose via header

#include <santoku/lua/utils.h>
#include <ctype.h>

static inline int number (lua_State *L)
{
  lua_settop(L, 3);
  size_t len;
  const char *str = luaL_checklstring(L, 1, &len);
  lua_Integer s = luaL_checkinteger(L, 2) - 1;
  if (s > (int64_t) len)
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

static inline int equals (lua_State *L)
{
  lua_settop(L, 4);
  size_t litlen;
  const char *lit = luaL_checklstring(L, 1, &litlen);
  size_t chunklen;
  const char *chunk = luaL_checklstring(L, 2, &chunklen);
  lua_Integer s = luaL_checkinteger(L, 3);
  if (s < 1) {
    lua_pushboolean(L, false);
    return 1;
  }
  if (s > (int64_t) chunklen) {
    lua_pushboolean(L, false);
    return 1;
  }
  lua_Integer e = luaL_checkinteger(L, 4);
  if (e < 1) {
    lua_pushboolean(L, false);
    return 1;
  }
  lua_pushboolean(L, strncmp(lit, chunk + s - 1, (size_t) (e - s + 1)) == 0);
  return 1;
}

static const char hex[] = "0123456789ABCDEF";

static inline int to_hex (lua_State *L)
{
  size_t size0;
  const char *data = luaL_checklstring(L, 1, &size0);
  size_t size1 = size0 * 2;
  char *out = malloc(size1 + 1);
  if (!out) return tk_lua_errmalloc(L);
  for (size_t i = 0; i < size0; ++i) {
    unsigned char byte = (unsigned char) data[i];
    out[i * 2] = hex[byte >> 4];
    out[i * 2 + 1] = hex[byte & 0x0F];
  }
  lua_pushlstring(L, out, (size_t) size1);
  free(out);
  return 1;
}

static inline int from_hex (lua_State *L) {
  size_t size0;
  const char *data = luaL_checklstring(L, 1, &size0);
  if (size0 % 2 != 0)
    return tk_lua_error(L, "Invalid hex string length");
  size_t size1 = size0 / 2;
  char *out = malloc(size1);
  if (!out) return tk_lua_errmalloc(L);
  for (size_t i = 0; i < size0; i += 2) {
    int high = data[i];
    int low = data[i + 1];
    if (!isxdigit(high) || !isxdigit(low)) {
      free(out);
      return tk_lua_error(L, "Invalid hex character");
    }
    high = (isdigit(high) ? high - '0' : (toupper(high) - 'A' + 10));
    low = (isdigit(low) ? low - '0' : (toupper(low) - 'A' + 10));
    out[i / 2] = (high << 4) | low;
  }
  lua_pushlstring(L, out, (size_t) size1);
  free(out);
  return 1;
}

static unsigned char b64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static unsigned char b64url[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

static inline int to_base64 (lua_State *L)
{
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  bool url = lua_toboolean(L, 2);
  unsigned char *enc = url ? b64url : b64;
  int64_t i, j;
  i = j = 0;
  size_t size = 0;
  unsigned char buf[4] = {0};
  unsigned char tmp[3] = {0};
  char *out = malloc(((len + 2) / 3) * 4);
  if (!out) return tk_lua_errmalloc(L);
  while (len--) {
    tmp[i++] = (unsigned char) *(src++);
    if (3 == i) {
      buf[0] = (tmp[0] & 0xfc) >> 2;
      buf[1] = ((tmp[0] & 0x03) << 4) + ((tmp[1] & 0xf0) >> 4);
      buf[2] = ((tmp[1] & 0x0f) << 2) + ((tmp[2] & 0xc0) >> 6);
      buf[3] = tmp[2] & 0x3f;
      for (i = 0; i < 4; ++i)
        out[size++] = (char) enc[buf[i]];
      i = 0;
    }
  }
  if (i > 0) {
    for (j = i; j < 3; ++j)
      tmp[j] = '\0';
    buf[0] = (tmp[0] & 0xfc) >> 2;
    buf[1] = ((tmp[0] & 0x03) << 4) + ((tmp[1] & 0xf0) >> 4);
    buf[2] = ((tmp[1] & 0x0f) << 2) + ((tmp[2] & 0xc0) >> 6);
    buf[3] = tmp[2] & 0x3f;
    for (j = 0; (j < i + 1); ++j)
      out[size++] = (char) enc[buf[j]];
    while ((i++ < 3))
      out[size++] = '=';
  }
  lua_pushlstring(L, out, (size_t) size);
  free(out);
  return 1;
}

static inline int from_base64 (lua_State *L)
{
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  bool url = lua_toboolean(L, 2);
  unsigned char *enc = url ? b64url : b64;
  int64_t i, j, l;
  i = j = l = 0;
  size_t size = 0;
  unsigned char buf[3];
  unsigned char tmp[4];
  char *out = malloc((len * 3) / 4);
  if (!out) return tk_lua_errmalloc(L);
  while (len--) {
    if ('=' == src[j] || !(isalnum(src[j]) || (url
        ? ('-' == src[j] || '_' == src[j])
        : ('+' == src[j] || '/' == src[j]))))
      break;
    tmp[i++] = (unsigned char) src[j++];
    if (4 == i) {
      for (i = 0; i < 4; ++i)
        for (l = 0; l < 64; ++l)
          if (tmp[i] == enc[l]) {
            tmp[i] = l;
            break;
          }
      buf[0] = (tmp[0] << 2) + ((tmp[1] & 0x30) >> 4);
      buf[1] = ((tmp[1] & 0xf) << 4) + ((tmp[2] & 0x3c) >> 2);
      buf[2] = ((tmp[2] & 0x3) << 6) + tmp[3];
      for (i = 0; i < 3; ++i)
        out[size++] = (char) buf[i];
      i = 0;
    }
  }
  if (i > 0) {
    for (j = i; j < 4; ++j)
      tmp[j] = '\0';
    for (j = 0; j < 4; ++j)
      for (l = 0; l < 64; ++l)
        if (tmp[j] == enc[l]) {
          tmp[j] = l;
          break;
        }
    buf[0] = (tmp[0] << 2) + ((tmp[1] & 0x30) >> 4);
    buf[1] = ((tmp[1] & 0xf) << 4) + ((tmp[2] & 0x3c) >> 2);
    buf[2] = ((tmp[2] & 0x3) << 6) + tmp[3];
    for (j = 0; (j < i - 1); ++j)
      out[size++] = (char) buf[j];
  }
  lua_pushlstring(L, out, (size_t) size);
  free(out);
  return 1;
}

static inline int to_base64_url (lua_State *L)
{
  lua_settop(L, 1);
  lua_pushboolean(L, true);
  return to_base64(L);
}

static inline int from_base64_url (lua_State *L)
{
  lua_settop(L, 1);
  lua_pushboolean(L, true);
  return from_base64(L);
}

static inline int to_url (lua_State *L)
{
  size_t size0;
  const char *data = luaL_checklstring(L, 1, &size0);
  size_t size1 = size0 * 3;
  char *out = malloc(size1 + 1);
  if (!out) return tk_lua_errmalloc(L);
  int64_t i, j;
  for (i = 0, j = 0; i < (int64_t) size0; i ++) {
    unsigned char d = (unsigned char) data[i];
    if (isalnum(d) || strchr("-_.~", d)) {
      out[j++] = (char) d;
    } else {
      sprintf(out + j, "%%%02x", d);
      j += 3;
    }
  }
  lua_pushlstring(L, out, (size_t) j);
  free(out);
  return 1;
}

static inline int from_url (lua_State *L) {
  size_t size0;
  const char *data = luaL_checklstring(L, 1, &size0);
  size_t size1 = size0;
  char *out = malloc(size1 + 1);
  if (!out) return tk_lua_errmalloc(L);
  int64_t i, j = 0;
  for (i = 0; i < (int64_t) size0; i++) {
    unsigned char d = (unsigned char) data[i];
    if (d == '%') {
      if (i + 2 < (int64_t) size0) {
        char hex[3] = { data[i + 1], data[i + 2], 0 };
        out[j++] = (char) strtol(hex, NULL, 16);
        i += 2;
      } else {
        free(out);
        return tk_lua_error(L, "Invalid URL encoding");
      }
    } else {
      out[j++] = (char) d;
    }
  }
  lua_pushlstring(L, out, (size_t) j);
  free(out);
  return 1;
}

static inline void parse_url_decode_to (const char *src, size_t len, luaL_Buffer *B)
{
  for (size_t i = 0; i < len; i++) {
    if (src[i] == '%' && i + 2 < len && isxdigit(src[i+1]) && isxdigit(src[i+2])) {
      int high = src[i+1];
      int low = src[i+2];
      high = isdigit(high) ? high - '0' : toupper(high) - 'A' + 10;
      low = isdigit(low) ? low - '0' : toupper(low) - 'A' + 10;
      luaL_addchar(B, (char)((high << 4) | low));
      i += 2;
    } else if (src[i] == '+') {
      luaL_addchar(B, ' ');
    } else {
      luaL_addchar(B, src[i]);
    }
  }
}

static inline void parse_url_set_param (lua_State *L, int tbl_idx, const char *qstr, size_t qlen)
{
  const char *p = qstr;
  const char *end = qstr + qlen;
  while (p < end) {
    const char *amp = memchr(p, '&', (size_t)(end - p));
    if (!amp) amp = end;
    const char *eq = memchr(p, '=', (size_t)(amp - p));
    if (eq) {
      luaL_Buffer B;
      luaL_buffinit(L, &B);
      parse_url_decode_to(p, (size_t)(eq - p), &B);
      luaL_pushresult(&B);
      luaL_buffinit(L, &B);
      parse_url_decode_to(eq + 1, (size_t)(amp - eq - 1), &B);
      luaL_pushresult(&B);
      const char *v = lua_tostring(L, -1);
      if (strcmp(v, "true") == 0) {
        lua_pop(L, 1);
        lua_pushboolean(L, 1);
      } else if (strcmp(v, "false") == 0) {
        lua_pop(L, 1);
        lua_pushboolean(L, 0);
      } else {
        char *endptr;
        double num = strtod(v, &endptr);
        if (*endptr == '\0' && endptr != v) {
          lua_pop(L, 1);
          lua_pushnumber(L, num);
        }
      }
      lua_settable(L, tbl_idx);
    }
    p = amp + 1;
  }
}

static inline int parse_url (lua_State *L)
{
  size_t len;
  const char *url = luaL_optlstring(L, 1, NULL, &len);
  int has_result = lua_type(L, 2) == LUA_TTABLE;

  if (has_result) {
    lua_settop(L, 2);
  } else {
    lua_settop(L, 1);
    lua_newtable(L);
  }
  int result = lua_gettop(L);

  lua_pushnil(L); lua_setfield(L, result, "scheme");
  lua_pushnil(L); lua_setfield(L, result, "userinfo");
  lua_pushnil(L); lua_setfield(L, result, "host");
  lua_pushnil(L); lua_setfield(L, result, "port");
  lua_pushnil(L); lua_setfield(L, result, "fragment");

  lua_getfield(L, result, "path");
  if (lua_type(L, -1) != LUA_TTABLE) {
    lua_pop(L, 1);
    lua_newtable(L);
    lua_pushvalue(L, -1);
    lua_setfield(L, result, "path");
  }
  int path_tbl = lua_gettop(L);
  for (int i = (int)lua_objlen(L, path_tbl); i >= 1; i--) {
    lua_pushnil(L);
    lua_rawseti(L, path_tbl, i);
  }

  lua_getfield(L, result, "params");
  if (lua_type(L, -1) != LUA_TTABLE) {
    lua_pop(L, 1);
    lua_newtable(L);
    lua_pushvalue(L, -1);
    lua_setfield(L, result, "params");
  }
  int params_tbl = lua_gettop(L);
  lua_pushnil(L);
  while (lua_next(L, params_tbl)) {
    lua_pop(L, 1);
    lua_pushvalue(L, -1);
    lua_pushnil(L);
    lua_settable(L, params_tbl);
  }

  if (!url) {
    lua_pushvalue(L, result);
    return 1;
  }

  const char *p = url;
  const char *end = url + len;

  const char *hash = memchr(p, '#', (size_t)(end - p));
  if (hash) {
    lua_pushlstring(L, hash + 1, (size_t)(end - hash - 1));
    lua_setfield(L, result, "fragment");
    end = hash;
  }

  const char *ques = memchr(p, '?', (size_t)(end - p));
  const char *query = NULL;
  size_t query_len = 0;
  if (ques) {
    query = ques + 1;
    query_len = (size_t)(end - query);
    end = ques;
  }

  const char *colon = memchr(p, ':', (size_t)(end - p));
  if (colon && colon > p) {
    int valid_scheme = 1;
    if (!isalpha(p[0])) valid_scheme = 0;
    for (const char *s = p + 1; valid_scheme && s < colon; s++) {
      if (!isalnum(*s) && *s != '+' && *s != '-' && *s != '.') valid_scheme = 0;
    }
    if (valid_scheme) {
      char *scheme = malloc((size_t)(colon - p + 1));
      if (!scheme) return tk_lua_errmalloc(L);
      for (size_t i = 0; i < (size_t)(colon - p); i++)
        scheme[i] = tolower(p[i]);
      scheme[colon - p] = '\0';
      lua_pushstring(L, scheme);
      free(scheme);
      lua_setfield(L, result, "scheme");
      p = colon + 1;
    }
  }

  if (end - p >= 2 && p[0] == '/' && p[1] == '/') {
    p += 2;
    const char *auth_end = p;
    while (auth_end < end && *auth_end != '/') auth_end++;
    const char *auth_start = p;
    size_t auth_len = (size_t)(auth_end - auth_start);

    const char *at = memchr(auth_start, '@', auth_len);
    if (at) {
      lua_pushlstring(L, auth_start, (size_t)(at - auth_start));
      lua_setfield(L, result, "userinfo");
      auth_start = at + 1;
      auth_len = (size_t)(auth_end - auth_start);
    }

    if (auth_len > 0 && auth_start[0] == '[') {
      const char *bracket_end = memchr(auth_start, ']', auth_len);
      if (bracket_end) {
        lua_pushlstring(L, auth_start + 1, (size_t)(bracket_end - auth_start - 1));
        lua_setfield(L, result, "host");
        if (bracket_end + 1 < auth_end && bracket_end[1] == ':') {
          long port = strtol(bracket_end + 2, NULL, 10);
          if (port > 0) {
            lua_pushinteger(L, port);
            lua_setfield(L, result, "port");
          }
        }
      }
    } else {
      const char *port_colon = memchr(auth_start, ':', auth_len);
      if (port_colon) {
        lua_pushlstring(L, auth_start, (size_t)(port_colon - auth_start));
        lua_setfield(L, result, "host");
        long port = strtol(port_colon + 1, NULL, 10);
        if (port > 0) {
          lua_pushinteger(L, port);
          lua_setfield(L, result, "port");
        }
      } else if (auth_len > 0) {
        lua_pushlstring(L, auth_start, auth_len);
        lua_setfield(L, result, "host");
      }
    }
    p = auth_end;
  }

  lua_pushlstring(L, p, (size_t)(end - p));
  lua_setfield(L, result, "pathname");

  int path_idx = 1;
  while (p < end) {
    while (p < end && *p == '/') p++;
    if (p >= end) break;
    const char *seg_end = p;
    while (seg_end < end && *seg_end != '/') seg_end++;
    lua_pushlstring(L, p, (size_t)(seg_end - p));
    lua_rawseti(L, path_tbl, path_idx++);
    p = seg_end;
  }

  if (query) {
    lua_pushliteral(L, "?");
    lua_pushlstring(L, query, query_len);
    lua_concat(L, 2);
    lua_setfield(L, result, "search");
    parse_url_set_param(L, params_tbl, query, query_len);
  } else {
    lua_pushliteral(L, "");
    lua_setfield(L, result, "search");
  }

  lua_pushvalue(L, result);
  return 1;
}

static luaL_Reg fns[] =
{
  { "to_hex", to_hex },
  { "to_base64", to_base64 },
  { "to_base64_url", to_base64_url },
  { "to_url", to_url },

  { "from_hex", from_hex },
  { "from_base64", from_base64 },
  { "from_base64_url", from_base64_url },
  { "from_url", from_url },

  { "number", number },
  { "equals", equals },

  { "parse_url", parse_url },

  { NULL, NULL }
};

int luaopen_santoku_string_base (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_register(L, NULL, fns); // mt
  return 1;
}
