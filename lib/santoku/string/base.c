#include "lua.h"
#include "lauxlib.h"

#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>

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

static int number (lua_State *L)
{
  lua_settop(L, 3);
  size_t len;
  const char *str = luaL_checklstring(L, 1, &len);
  lua_Integer s = luaL_checkinteger(L, 2) - 1;
  if (s > len)
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

static int equals (lua_State *L)
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
  if (s > chunklen) {
    lua_pushboolean(L, false);
    return 1;
  }
  lua_Integer e = luaL_checkinteger(L, 4);
  if (e < 1) {
    lua_pushboolean(L, false);
    return 1;
  }
  lua_pushboolean(L, strncmp(lit, chunk + s - 1, e - s + 1) == 0);
  return 1;
}

static int to_hex (lua_State *L)
{
  size_t size0;
  const char *data = luaL_checklstring(L, 1, &size0);
  size_t size1 = size0 * 2;
  char *out = malloc(size1 + 1);
  if (!out) return tk_lua_errmalloc(L);
  for (size_t i = 0; i < size0; ++i)
    sprintf(out + i * 2, "%02X", data[i]);
  lua_pushlstring(L, out, size1);
  free(out);
  return 1;
}

static int from_hex (lua_State *L) {
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
  lua_pushlstring(L, out, size1);
  free(out);
  return 1;
}

/* Attribution for original implementation to_base64 function:
 *
 * Copyright (c) 2005-2011, Jouni Malinen <j@w1.fi>
 * This software may be distributed under the terms of the BSD license.
 *
 * Modified for lua integration and url handling */
static unsigned char b64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static unsigned char b64url[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
static int to_base64 (lua_State *L)
{
  size_t len;
  const unsigned char *src = (const unsigned char *) luaL_checklstring(L, 1, &len);
  bool url = lua_toboolean(L, 2);
  unsigned char *enc = url ? b64url : b64;
	unsigned char *out, *pos;
	const unsigned char *end, *in;
	size_t olen;
	int line_len;
	olen = len * 4 / 3 + 4;
	olen += olen / 72;
	if (olen < len)
		return tk_lua_error(L, "Output length is too long");
	out = malloc(olen);
	if (out == NULL)
		return tk_lua_errmalloc(L);
	end = src + len;
	in = src;
	pos = out;
	line_len = 0;
	while (end - in >= 3) {
		*pos++ = enc[in[0] >> 2];
		*pos++ = enc[((in[0] & 0x03) << 4) | (in[1] >> 4)];
		*pos++ = enc[((in[1] & 0x0f) << 2) | (in[2] >> 6)];
		*pos++ = enc[in[2] & 0x3f];
		in += 3;
		line_len += 4;
		if (line_len >= 72) {
			*pos++ = '\n';
			line_len = 0;
		}
	}
	if (end - in) {
		*pos++ = enc[in[0] >> 2];
		if (end - in == 1) {
			*pos++ = enc[(in[0] & 0x03) << 4];
			*pos++ = '=';
		} else {
			*pos++ = enc[((in[0] & 0x03) << 4) |
					      (in[1] >> 4)];
			*pos++ = enc[(in[1] & 0x0f) << 2];
		}
		*pos++ = '=';
		line_len += 4;
	}
	if (line_len)
		*pos++ = '\n';
  olen = pos - out;
  lua_pushlstring(L, (char *)out, olen);
  free(out);
  return 1;
}

/* Attribution for original implementation from_base64 function:
 *
 * Copyright (c) 2005-2011, Jouni Malinen <j@w1.fi>
 * This software may be distributed under the terms of the BSD license.
 *
 * Modified for lua integration and url handling */
static int from_base64 (lua_State *L)
{
  size_t len;
  const unsigned char *src = (const unsigned char *) luaL_checklstring(L, 1, &len);
  bool url = lua_toboolean(L, 2);
  unsigned char *enc = url ? b64url : b64;
	unsigned char dtable[256], *out, *pos, block[4], tmp;
	size_t i, count, olen;
	int pad = 0;
	memset(dtable, 0x80, 256);
	for (i = 0; i < sizeof(b64) - 1; i++)
		dtable[enc[i]] = (unsigned char) i;
	dtable['='] = 0;
	count = 0;
	for (i = 0; i < len; i++)
		if (dtable[src[i]] != 0x80)
			count++;
	if (count == 0) {
    lua_pushstring(L, "");
    return 1;
  }
	olen = count / 4 * 3;
	pos = out = malloc(olen);
	if (out == NULL)
    return tk_lua_errmalloc(L);
	count = 0;
	for (i = 0; i < len; i++) {
		tmp = dtable[src[i]];
		if (tmp == 0x80)
			continue;
		if (src[i] == '=')
			pad++;
		block[count] = tmp;
		count++;
		if (count == 4) {
			*pos++ = (block[0] << 2) | (block[1] >> 4);
			*pos++ = (block[1] << 4) | (block[2] >> 2);
			*pos++ = (block[2] << 6) | block[3];
			count = 0;
			if (pad) {
				if (pad == 1)
					pos--;
				else if (pad == 2)
					pos -= 2;
				else {
					free(out);
					return tk_lua_error(L, "Invalid base64 padding");
				}
				break;
			}
		}
	}
	olen = pos - out;
  lua_pushlstring(L, (char *)out, olen);
  free(out);
	return 1;
}

static int to_base64_url (lua_State *L)
{
  lua_settop(L, 1);
  lua_pushboolean(L, true);
  return to_base64(L);
}

static int from_base64_url (lua_State *L)
{
  lua_settop(L, 1);
  lua_pushboolean(L, true);
  return from_base64(L);
}

static int to_url (lua_State *L)
{
  size_t size0;
  const char *data = luaL_checklstring(L, 1, &size0);
  size_t size1 = size0 * 3;
  char *out = malloc(size1 + 1);
  if (!out) return tk_lua_errmalloc(L);
  int i, j;
  for (i = 0, j = 0; i < size0; i++) {
    unsigned char d = data[i];
    if (isalnum(d) || strchr("-_.~", d)) {
      out[j++] = d;
    } else {
      sprintf(out + j, "%%%02x", d);
      j += 3;
    }
  }
  lua_pushlstring(L, out, j);
  free(out);
  return 1;
}

static int from_url (lua_State *L) {
  size_t size0;
  const char *data = luaL_checklstring(L, 1, &size0);
  size_t size1 = size0; // Worst case nothing encoded
  char *out = malloc(size1 + 1);
  if (!out) return tk_lua_errmalloc(L);
  int i, j = 0;
  for (i = 0; i < size0; i++) {
    unsigned char d = data[i];
    if (d == '%') {
      if (i + 2 < size0) {
        char hex[3] = { data[i + 1], data[i + 2], 0 };
        out[j++] = (char) strtol(hex, NULL, 16);
        i += 2;
      } else {
        free(out);
        return tk_lua_error(L, "Invalid URL encoding");
      }
    } else {
      out[j++] = d;
    }
  }
  lua_pushlstring(L, out, j);
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
