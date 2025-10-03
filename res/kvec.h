/* The MIT License

   Copyright (c) 2008, by Attractive Chaos <attractor@live.co.uk>

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   "Software"), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
*/

/*
  An example:

#include "kvec.h"
int main() {
	kvec_t(int) array;
	kv_init(array);
	kv_push(int, array, 10); // append
	kv_a(int, array, 20) = 5; // dynamic
	kv_A(array, 20) = 4; // static
	kv_destroy(array);
	return 0;
}
*/

/*
  2008-09-22 (0.1.0):

	* The initial version.

*/

#ifndef AC_KVEC_H
#define AC_KVEC_H

#include <stdlib.h>
#include <stdbool.h>

#define kv_roundup32(x) (--(x), (x)|=(x)>>1, (x)|=(x)>>2, (x)|=(x)>>4, (x)|=(x)>>8, (x)|=(x)>>16, ++(x))

#define kvec_t(type) struct { size_t n, m; type *a; bool lua_managed; }
#define kv_init(v, lua_managed) ((v).n = (v).m = 0, (v).a = 0, (v).lua_managed = (lua_managed))
#define kv_destroy(v) free((v).a)
#define kv_pop(v) ((v).a[--(v).n])
#define kv_size(v) ((v).n)
#define kv_max(v) ((v).m)

#define kv_resize(type, v, s) ({ \
	size_t _new_m = (s); \
	type *_new_a = (type*)realloc((v).a, sizeof(type) * _new_m); \
	int _ok = (_new_a != NULL || _new_m == 0); \
	if (_ok) { (v).a = _new_a; (v).m = _new_m; } \
	_ok ? 0 : -1; \
})

#define kv_copy(type, v1, v0) ({ \
	int _rc = 0; \
	if ((v1).m < (v0).n) { \
		_rc = kv_resize(type, v1, (v0).n); \
	} \
	if (_rc == 0) { \
		(v1).n = (v0).n; \
		memcpy((v1).a, (v0).a, sizeof(type) * (v0).n); \
	} \
	_rc; \
})

#define kv_push(type, v, x) ({ \
	int _rc = 0; \
	if ((v).n == (v).m) { \
		size_t _new_m = (v).m ? (v).m << 1 : 2; \
		type *_new_a = (type*)realloc((v).a, sizeof(type) * _new_m); \
		if (_new_a == NULL) { \
			_rc = -1; \
		} else { \
			(v).a = _new_a; \
			(v).m = _new_m; \
		} \
	} \
	if (_rc == 0) \
		(v).a[(v).n++] = (x); \
	_rc; \
})

#define kv_pushp(type, v) ({ \
	type *_ret = NULL; \
	if ((v).n == (v).m) { \
		size_t _new_m = (v).m ? (v).m << 1 : 2; \
		type *_new_a = (type*)realloc((v).a, sizeof(type) * _new_m); \
		if (_new_a != NULL) { \
			(v).a = _new_a; \
			(v).m = _new_m; \
			_ret = (v).a + (v).n++; \
		} \
	} else { \
		_ret = (v).a + (v).n++; \
	} \
	_ret; \
})

#endif
