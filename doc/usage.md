# Using santoku

Worked examples for each module. See the [README](../README.md) for orientation and the
module map. **The tests are the spec**: every section names the test that covers the rest.

Recurring idioms:
- **Extended stdlib.** `string`/`table`/`num`/`random`/`utc` merge the stock library in.
- **mutate vs copy.** `array`/`table` ops mutate and return self; `-ed` variants copy.
- **structured errors.** values flow through `error`/`assert`/`pcall` as a tuple.
- **predicates return diagnostics.** `false, reason, ...`, composable with `assert`.
- **load-only tools.** `autoserialize`/`profile`/`trace` install hooks on `require`.

---

## string  ·  `test/spec/santoku/string.lua`

```lua
local str = require("santoku.string")

str.splits("a b  c", "%s+")              -- { "a", "b", "c" }
str.splits("a b c", "%s+", true)          -- keep delimiters: { "a", " ", "b", " ", "c" }
str.splits("a b c", "%s+", "left")        -- attach delim left: { "a ", "b ", "c" }
str.matches("10 39.5", "%S+")             -- { "10", "39.5" }
str.count("abab", "ab")                   -- 2

str.interp("Hello %who, %adj", { who = "World", adj = "nice" })
str.interp("%1 %3 %2", { "a", "b", "c" })          -- positional -> "a c b"
str.interp("%.1f#(score)", { score = 1 })          -- format + named key -> "1.0"
str.parse("2024-04-08", "(%d+)#(y)-(%d+)#(m)-(%d+)#(d)")  -- { y=, m=, d= }

str.trim("  x  ")                         -- "x"  (str.trim(s, leftpat, rightpat))
str.quote("hi"); str.unquote('"hi"')      -- '"hi"' ; "hi"
str.startswith(s, p); str.endswith(s, p); str.stripprefix("/a/b", "/a/")
str.escape("a.b*c")                       -- "a%.b%*c"  (str.unescape reverses)
str.commonprefix("hello", "help")         -- "hel"
str.format_number(12345678)               -- "12,345,678"

-- url / query (C-backed codecs underneath)
str.to_url(s); str.from_url(s)            -- percent-encoding
str.to_base64(s); str.from_base64(s); str.to_base64_url(s)
str.to_hex(s); str.from_hex(s)
str.to_query({ a = 1, b = true })         -- "?a=1&b=true"  (str.from_query reverses)
str.encode_url({ scheme = "https", host = "x.com", pathname = "/p" })  -- builds a URL
```

## table  ·  `test/spec/santoku/table.lua`

```lua
local tbl = require("santoku.table")

tbl.get(obj, { "a", "b", 3 })             -- nested read, nil-safe
tbl.set(obj, { "a", "b" }, v)             -- creates intermediate tables
tbl.update(obj, { "a" }, fun.bind(op.add, 1))
tbl.merge({}, t1, t2)                      -- recursive (later args don't overwrite existing)
tbl.assign({}, t1, t2)                     -- shallow, no-overwrite
tbl.equals(a, b)                           -- deep compare; returns true | false, why, ...
tbl.map(t, fn)                             -- in place over values
tbl.keys(t); tbl.vals(t); tbl.entries(t)   -- arrays
tbl.invert({ a = 1 })                      -- { [1] = "a" }
tbl.from(arr, function (v) return v.id end)  -- index an array by a key fn
tbl.clear(t); tbl.each(t, fn)
```

## array  ·  `test/spec/santoku/array.lua`

The largest module. Sequence ops default to **mutate-and-return-self**; `-ed` twins copy.

```lua
local arr = require("santoku.array")

arr.push(t, a, b); arr.pop(t); arr.shift(t)        -- pop/shift return (t, removed)
arr.slice(t, 2, 4); arr.take(t, 2); arr.drop(t, 2); arr.takelast / arr.droplast
arr.insert(t, i, v); arr.remove(t, i, j); arr.clear(t, i, j); arr.trunc(t, i)
arr.copy(dest, src, ss, se, ds); arr.move(...)     -- range copy/move
arr.map(t, fn); arr.filter(t, pred); arr.reduce(t, fn[, init])
arr.mapped / arr.filtered / arr.sorted / arr.compacted / arr.uniqued   -- copy variants
arr.sort(t, { unique = true }); arr.sort(t, cmpfn); arr.reverse(t)
arr.find(t, pred); arr.includes(t, v1, v2); arr.tabulate({1,2}, "a", "b")

-- set / grouping / restructure
arr.unique(t); arr.compact(t); arr.flatten(nested[, depth]); arr.toset(t)
arr.group(t, keyfn); arr.partition(t, pred); arr.zip(a, b); arr.unzip(z)
arr.range(1, 5); arr.range(2, 6, 2); arr.chunked(t, 2); arr.interleaved(t, sep)
arr.shuffle(t[, i, j])

-- iterator drivers (consume a stateless iterator like ipairs/pairs/coroutine.wrap)
arr.imap(fn, ipairs(t)); arr.ifilter(pred, pairs(t)); arr.ireduce(fn, init, ipairs(t))
arr.icollect(iter); arr.icollect(3, iter); arr.icollect(dest, iter)   -- limit/dest optional

-- numeric (plain tables as vectors)
arr.sum/mean/max/min(t); arr.dot(a, b); arr.magnitude(v)
arr.scale(t, k); arr.add(t, k); arr.scalev(t, t2); arr.addv(t, t2); arr.abs(t)

-- varargs
arr.pack(...); arr.tup(...) -- (tup records .n, preserves nils); arr.spread(t)
```

## error  ·  `test/spec/santoku/error.lua`

Errors carry an arbitrary tuple of values, not just a message.

```lua
local err = require("santoku.error")

err.error("msg", 1, 2)                     -- raises; values preserved through pcall
local ok, a, b = err.pcall(fn, ...)        -- false, then the error tuple (unwrapped)
err.assert(cond, "why", extra)             -- assert that forwards the tuple on failure
err.xpcall(fn, handler)                     -- handler receives the unwrapped tuple
err.checknil(v, "msg"); err.checkok(ok, "msg")   -- guard nil/false-style returns
err.wrapnil(io.open); err.wrapok(fn)        -- adapt foreign return conventions -> raise
err.copcall(fn, ...); err.coxpcall(fn, h)   -- coroutine-safe pcall/xpcall (via santoku.co)
```

## validate  ·  `test/spec/santoku/validate.lua`

Every check returns `true`, or `false` plus a diagnostic tuple, usable as a boolean or `assert`-fed.

```lua
local vdt = require("santoku.validate")

vdt.isstring(x); vdt.isnumber; vdt.istable; vdt.isfunction; vdt.isuserdata
vdt.isboolean; vdt.isnil; vdt.isnotnil; vdt.istrue; vdt.isfalse; vdt.isprimitive
vdt.isarray(t)                             -- contiguous 1..n integer keys only
vdt.isfile(io.stdout)                      -- file-handle metatable check

vdt.isequal(a, b); vdt.isnotequal(a, b)
vdt.lt/gt/le/ge(n, limit); vdt.between(n, lo, hi)
vdt.matches(s, pat); vdt.notmatches(s, pat); vdt.hasargs(...)

-- metamethod capability checks (built-ins counted: numbers "hasadd", tables "haspairs", ...)
vdt.haspairs/hasipairs/hasindex/hasnewindex/haslen/hastostring/hascall/...
vdt.hasmetatable(v, mt)
```

## functional / op  ·  `test/spec/santoku/functional.lua`, `op.lua`

```lua
local fun = require("santoku.functional")
local op  = require("santoku.op")

fun.bind(op.div, 2)(4)                      -- 0.5  (partial-applies the first arg)
fun.compose(a, b)(x)                         -- a(b(x))
fun.sel(fn, 2)(1, 2, 3)                      -- calls fn with args from position 2
fun.take(fn, 2)(1, 2, 3, 4)                  -- calls fn(1, 2)
fun.choose(true, x, y)                        -- functional if; passes trailing args through
fun.maybe(g)(ok, ...)                         -- if ok -> true, g(...) else false, ...
fun.id; fun.noop; fun.const(42)
fun.get(p)(t) == t[p]; fun.set(p, v)(t)       -- + tget(t)(p) / tset(t, v)(p)

-- op: a function per operator
op.add op.sub op.mul op.div op.mod op.exp op.neg
op.eq op.neq op.lt op.gt op.lte op.gte op["and"] op["or"] op["not"]
op.len op.cat op.call(fn, ...)
```

## serialize  ·  `test/spec/santoku/serialize.lua`

```lua
local serialize = require("santoku.serialize")

serialize({ a = 1, b = { 2, 3 } })          -- pretty Lua source (module is callable)
serialize(value, true)                       -- minified
serialize(value, false, seen)                -- pass a 'seen' table to share cycle-tracking
serialize(value, false, nil, max_depth)      -- depth guard (default 200)
serialize.serialize_table_contents(t)        -- inner contents only (no surrounding braces)
local v = load("return " .. serialize(x))()  -- round-trip (functions/userdata can't serialize)
```

## async  ·  `test/spec/santoku/async.lua`

Continuation-passing control flow. A "node" is `function (done, ...) ... done(ok, ...) end`;
the final argument is a `done(ok, ...)` callback.

```lua
local async = require("santoku.async")

async.pipe(fetch, parse, function (ok, data) ... end)   -- thread a value through stages
async.pipe({ a, b, finish })                             -- array form
async.loop(function (loop, stop, ...) ... end, done)     -- call loop() to continue, stop() to end
async.race(a, b, done)                                   -- first to finish wins
async.each(t, fn, done); async.map(t, fn, done); async.filter(t, fn, done)
async.reduce(t, fn, done[, init])
async.all/mapall/filterall(t, fn, done)                  -- concurrent (no sequencing)
async.ieach/imap/ifilter/ifiltermap/ireduce(fn, [init,] done, ipairs(t))  -- over iterators

local ev = async.events()
ev.on("e", handler[, async])    -- async=true -> handler is (next, ...) and must call next
ev.off("e", handler); ev.emit("e", ...)
ev.process(ev, each, done, ...) -- run handlers as a pipeline
```

## num  ·  `test/spec/santoku/num.lua`

```lua
local num = require("santoku.num")          -- includes all of math.*
num.trunc(1.18901, 2)                       -- 1.18  (truncate to d decimals)
num.round(n); num.round(n, multiple)        -- nearest, or up to a multiple
num.atan(y, x)                              -- atan2 when x given, else atan
local avg = num.mavg(0.2); avg(v)           -- exponential moving average closure
```

## random  ·  `test/spec/santoku/random.lua`

```lua
local rand = require("santoku.random")      -- includes the fast C generator
rand.seed(); rand.num(); rand.num(1, 6)     -- num = math.random
rand.str(10); rand.str(10, 65, 90); rand.alnum(10)
rand.norm()                                  -- clamped normal in [-1, 1]
rand.fast_seed(s); rand.fast_random(); rand.fast_normal(mean, variance); rand.fast_max
rand.options({ k = iter, ... }, function (combo, n, key) ... end, unique, chunk)
```

## utc  ·  `test/spec/santoku/utc.lua`

```lua
local utc = require("santoku.utc")          -- includes the C time api
utc.date(ts)                                 -- -> { year, month, day, hour, min, sec, ... }
utc.time(date_table); utc.time(true)         -- table -> ts ; true -> now (subsecond)
utc.format(ts, "%Y-%m-%d")
utc.shift(ts, 1, "day", out); utc.trunc(ts, "day", out)
local lap = utc.stopwatch(); local dt, total = lap()   -- per-call + cumulative seconds
```

## geo  ·  `test/spec/santoku/geo.lua`

```lua
local geo = require("santoku.geo")
geo.distance({ x = 0, y = 0 }, { x = 2, y = 0 })   -- 2 (euclidean)
geo.angle(p1, p2); geo.rotate(p, origin, deg)
geo.earth_distance({ lat=, lon= }, { lat=, lon= })  -- great-circle km
geo.earth_stereo(point, origin); geo.bearing(p1, p2)
```

## fracidx  ·  `test/spec/santoku/fracidx.lua`

Sortable string keys for ordered insertion without renumbering.

```lua
local fi = require("santoku.fracidx")
fi.between(nil, nil)          -- "a0" (canonical first key)
fi.between("a0", "a1")        -- a key strictly between (lexicographically)
fi.between(prev, nil)         -- append after; fi.between(nil, next) -> prepend before
fi.between_n("a0", "a5", 4)   -- 4 evenly distributed keys
fi.validate(key)              -- raises on malformed keys (sync/import boundary guard)
```

## inherit  ·  `test/spec/santoku/inherit.lua`

```lua
local inherit = require("santoku.inherit")
inherit.pushindex(t, i)       -- push i onto t's metatable __index chain
inherit.popindex(t)           -- pop the most recent; getindex/setindex/hasindex(t, i)
```

## env  ·  `test/spec/santoku/env.lua`

```lua
local env = require("santoku.env")
env.var("HOME")               -- raises if unset
env.var("X", "default")       -- default when unset (env.var("X", nil) -> nil, no error)
env.interpreter(); env.interpreter(true)   -- reconstruct argv (true = include script args)
env.searchpath(name, path)    -- like package.searchpath
```

## co  ·  `test/spec/santoku/co.lua`

Coroutine factory whose yields are scoped to a private tag, so nested/library coroutines
don't intercept each other's yields.

```lua
local co_factory = require("santoku.co")
local co = co_factory()                       -- optional tag arg
local c = co.create(function (x) return co.yield(x) + 1 end)
local ok, v = co.resume(c, 10)                -- only this co's yields are seen here
local w = co.wrap(function () co.yield(1) end)
```

## bench  ·  `test/spec/santoku/bench.lua`

```lua
local bench = require("santoku.bench")
bench("tag", fn, ...)         -- GC twice, time fn(...), print "tag  seconds  result"
```

## lua  ·  `test/spec/santoku/lua.lua`

```lua
local lua = require("santoku.lua")
lua.loadstring("return 1 + 1")()       -- loadstring that raises on compile error
lua.loadstring(code, env)              -- compile under a custom environment
lua.getfenv(fn); lua.setfenv(fn, env)
lua.getupvalue(fn, "name"); lua.getupvalue(fn, 1)   -- -> name, value, index
lua.userdata({ __gc = fn })            -- fresh userdata with a metatable (e.g. for __gc hooks)
lua.malloc_trim()                       -- release free heap back to the OS (glibc only)
```

## test  ·  `test/spec/santoku/test.lua`

The runner the whole suite uses. Nest freely; on the first failure it prints the tag
breadcrumb, the error, and a traceback, then `os.exit(1)`.

```lua
local test = require("santoku.test")
test("group", function ()
  test("case", function ()
    assert(1 + 1 == 2)
  end)
end)
```

## Interpreter-load tools (auto-execute on require)

These install global hooks the moment they load; don't call them, load them:

```sh
lua -l santoku.autoserialize  script.lua   # global print() now serializes its arguments
lua -l santoku.profile        script.lua   # function-level profile, report at GC/exit
lua -l santoku.trace          script.lua   # line/return execution trace to stdout
```

The factories behind the last two are usable directly when you want explicit control:

```lua
local profiler = require("santoku.profiler")
local report = profiler()      -- starts profiling; call report() to print + stop
local tracer = require("santoku.tracer")
local stop = tracer()          -- starts tracing; call stop() to detach the hook
```
