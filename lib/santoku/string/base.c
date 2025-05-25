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

  { NULL, NULL }
};

int luaopen_santoku_string_base (lua_State *L)
{
  lua_newtable(L); // mt
  luaL_register(L, NULL, fns); // mt
  return 1;
}
