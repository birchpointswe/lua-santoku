# santoku

The base layer for the santoku ecosystem: a pure-Lua (plus a few small C extensions)
standard-library supplement. Data utilities (`string`/`table`/`array`), defensive
programming (`error`/`validate`), functional combinators (`functional`/`op`), value
`serialize`, async control flow, and assorted system/dev tools. Every other
santoku-* library depends on this one.

This README is a usage guide, not an API reference. **The tests are the spec**: each
module points at the test that exercises its full surface. Read those for the exhaustive
function list; read this (and `doc/usage.md`) for how each module is used.

## Conventions (shared across modules)

- **Extended stdlib.** `string`/`table`/`num`/`random`/`utc` each `merge` the stock Lua
  library in, so `require("santoku.string")` gives you `string.format` *and* `splits`.
  Drop-in replace the global and gain the extras.
- **In-place vs new.** `array`/`table` mutate-and-return-self by default (`map`, `filter`,
  `sort`, `reverse`, `clear`); the `-ed` twins return a fresh copy (`mapped`, `filtered`,
  `sorted`, `compacted`, `uniqued`).
- **Structured errors.** `santoku.error` carries multiple values through `error`/`assert`/
  `pcall` (not just a string); validators in `santoku.validate` return
  `false, reason, ...` so they compose with `assert`.
- **Predicates pull double duty.** A `validate.is*`/`has*` check returns plain `true`, or
  `false` plus a diagnostic tuple, usable as a boolean *or* fed straight to `assert`.
- **Interpreter tools auto-execute on load.** `autoserialize`, `profile`, `trace` install
  global hooks the moment they're required; load them with `lua -l ...`, don't call them.

## Module map

| Module | Role | Anchor test |
|--------|------|-------------|
| `string` | split/match/interp/parse, trim/quote, url+query, hex/base64 (C) | `string.lua` |
| `table` | get/set/update/merge/assign, equals, keys/vals/entries, invert | `table.lua` |
| `array` | the big sequence toolkit: map/filter/reduce, slice/zip, set ops, vec math | `array.lua` |
| `error` | structured multi-value error/assert/pcall/xpcall, wrapok/wrapnil, copcall | `error.lua` |
| `validate` | `is*`/`has*` type+metamethod predicates, comparators (return diagnostics) | `validate.lua` |
| `functional` | bind/compose/maybe/choose/take/sel, get/set closures | `functional.lua` |
| `op` | functions for every Lua operator (`add`, `eq`, `cat`, `call`, ...) | `op.lua` |
| `serialize` | Lua value → re-loadable Lua source (C; callable module) | `serialize.lua` (seed) |
| `async` | continuation-passing control flow: pipe/loop/race/each/events | `async.lua` |
| `num` | math + trunc/round/atan(2)/mavg moving-average | `num.lua` |
| `random` | seed/str/alnum/norm/options + fast MCG generator (C) | `random.lua` |
| `utc` | timestamp date/time/format/shift/trunc (C) + stopwatch | `utc.lua` |
| `geo` | 2D distance/angle/rotate + earth great-circle / stereographic | `geo.lua` |
| `fracidx` | fractional indexing: sortable string keys between two keys | `fracidx.lua` |
| `inherit` | metatable `__index` chain push/pop/has | `inherit.lua` |
| `env` | env vars, interpreter argv reconstruction, searchpath | `env.lua` |
| `co` | tagged coroutine factory (yields scoped by tag) | `co.lua` (seed) |
| `bench` | one-shot GC'd wall-clock timer | `bench.lua` (seed) |
| `lua` | loadstring-with-env, get/setfenv, getupvalue, userdata, malloc_trim | `lua.lua` (seed) |
| `test` | tiny test runner (tag + fn; prints stack + exits on failure) | `test.lua` (seed) |
| `autoserialize` | **load-only**: replaces global `print` to serialize its args | `autoserialize.lua` (seed) |
| `profiler` | factory: function-level call/time profiler, returns a report fn | `profiler.lua` (seed) |
| `profile` | **load-only**: arms `profiler` and reports at GC/exit | `profile.lua` (seed) |
| `tracer` | factory: line/return execution tracer, returns a stop fn | `tracer.lua` (seed) |
| `trace` | **load-only**: arms `tracer` at GC/exit | `trace.lua` (seed) |

Worked, per-module examples live in [`doc/usage.md`](doc/usage.md).

## Snippets (the main modules)

### Core data utilities: `string` / `table` / `array`

```lua
local str = require("santoku.string")
local tbl = require("santoku.table")
local arr = require("santoku.array")

str.splits("a b  c", "%s+")              -- { "a", "b", "c" }
str.interp("Hello %who", { who = "x" })  -- "Hello x"  (also %1 indices, %.1f#(key) fmt)
str.parse("2024-04-08", "(%d+)#(year)-(%d+)#(month)-(%d+)#(day)")  -- { year=, month=, day= }

tbl.get(t, { "a", "b", 3 })              -- nested read by path (nil-safe)
tbl.merge({}, defaults, overrides)       -- recursive merge ;  tbl.assign = shallow, no-overwrite
tbl.equals(a, b)                         -- deep compare (returns true | false + why)

arr.map({ 1, 2, 3 }, function (x) return x * 2 end)   -- in place -> { 2, 4, 6 }
arr.filtered(xs, pred)                                 -- copy variant ('-ed' = non-mutating)
local p, f = arr.partition(xs, pred)                  -- + group/unique/zip/chunked/flatten
arr.dot(a, b); arr.magnitude(v)                       -- plain-table vector math
```

### Defensive + validation DSL: `error` / `validate`

```lua
local err = require("santoku.error")
local vdt = require("santoku.validate")
local assert = err.assert

-- structured errors carry every value, not just a string
local ok, a, b, c = err.pcall(function () err.error("bad", 1, 2) end)  -- false, "bad", 1, 2

-- validators return true, or false + a diagnostic tuple -> compose with assert
assert(vdt.isstring(x))                  -- raises "Value must be of type string", x, type(x)
assert(vdt.between(n, 0, 10))
if vdt.isarray(t) then ... end           -- also usable as a plain boolean

-- adapt foreign return styles into structured errors
local f = err.wrapnil(io.open)           -- nil-on-error  -> raises
local g = err.wrapok(some_ok_style_fn)   -- false-on-error -> raises
```

### Functional combinators: `functional` / `op`

```lua
local fun = require("santoku.functional")
local op  = require("santoku.op")

arr.map({ 1, 2, 3 }, fun.bind(op.add, 10))     -- { 11, 12, 13 }
local f = fun.compose(a, b)                     -- f(x) = a(b(x))
fun.choose(cond, x, y)                          -- functional if (passes trailing args through)
fun.maybe(fun.bind(op.div, 8))(true, 2)         -- true, 4   (short-circuits on a false flag)
local name = fun.get("name")                    -- name(t) == t.name
op.call(math.min, 5, 10)                         -- op.* covers every operator: add/eq/cat/len/...
```

### Serialization: `serialize`

```lua
local serialize = require("santoku.serialize")

serialize({ a = 1, b = { 2, 3 } })       -- pretty Lua source (module is callable)
serialize(value, true)                    -- minified (2nd arg)
local v = load("return " .. serialize(x))()   -- round-trip: output is loadable Lua
```

## Building / testing

This repo uses the `toku` build harness. Tests live in `test/spec/santoku/`; each spec is a
standalone Lua file that requires its module and runs `santoku.test` cases. The C extensions
(`serialize`, `string.base`, `random.fast`, `utc.capi`, `validate.capi`, `lua.lua`) are built
by the harness; run the suite through `toku` so the natives are compiled and on the path.

## License

MIT License

Copyright 2025 Birch Point SWE

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
