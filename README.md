# Santoku (base library)

Santoku is a comprehensive Lua utility library providing functional programming, asynchronous operations, data manipulation, testing, and system interaction capabilities.

## Module Reference

### `santoku.array`
Array manipulation and functional operations on sequential tables.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `pack` | `...` | `table` | Packs arguments into array |
| `spread` | `t, [start], [end]` | `...` | Unpacks array as arguments |
| `concat` | `t, [delim], [start], [end]` | `string` | Concatenates array elements to string |
| `insert` | `t, [i], v` | `t` | Inserts value at position (default: end) |
| `replicate` | `t, n` | `t` | Replicates array contents n times |
| `sort` | `t, [opts/fn]` | `t` | Sorts array in-place with optional unique filter |
| `shift` | `t` | `t` | Removes and returns first element |
| `pop` | `t` | `t` | Removes and returns last element |
| `slice` | `s, [start], [end]` | `table` | Returns array slice |
| `find` | `t, fn, ...` | `value, index` | Finds first matching element |
| `copy` | `dest, src, [di], [si], [se]` | `dest` | Copies array elements |
| `move` | `dest, src, [di], [si], [se]` | `dest` | Moves array elements |
| `clear` | `t, [start], [end]` | `t` | Clears array range |
| `remove` | `t, [start], [end]` | `t` | Removes array range |
| `trunc` | `t, [i]` | `t` | Truncates array at position |
| `extend` | `t, ...` | `t` | Appends multiple arrays |
| `overlay` | `t, i, ...` | `t` | Overlays values at position |
| `push` | `t, ...` | `t` | Appends values to array |
| `each` | `t, fn, ...` | `t` | Applies function to each element |
| `map` | `t, fn, ...` | `t` | Maps function over array in-place |
| `reduce` | `t, acc, [init]` | `value` | Reduces array with accumulator |
| `filter` | `t, fn, ...` | `t` | Filters array in-place |
| `tabulate` | `t, [opts], ...keys` | `table` | Converts array to key-value table |
| `includes` | `t, ...values` | `boolean` | Checks if array contains values |
| `reverse` | `t` | `t` | Reverses array in-place |
| `shuffle` | `...tables` | `nil` | Shuffles arrays in-place |
| `sum` | `t, [start], [end]` | `number` | Sums numeric array |
| `mean` | `t, [start], [end]` | `number` | Calculates arithmetic mean |
| `max` | `t` | `number` | Returns maximum value |
| `min` | `t` | `number` | Returns minimum value |

### `santoku.async`
Asynchronous programming utilities with event-driven patterns.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `pipe` | `...fns` | `function` | Creates async pipeline from functions |
| `each` | `generator, iterator, done` | `nil` | Async iteration over generator |
| `iter` | `yielder, iterator, done` | `nil` | Async iteration with yielding |
| `loop` | `loop_fn, final_fn` | `nil` | Creates async loop |
| `id` | `callback, ...` | `nil` | Identity function with callback |
| `ipairs` | `callback, table, userdata` | `nil` | Async ipairs iteration |
| `events` | `()` | `emitter` | Creates event emitter with `on`, `off`, `emit`, `process` |

### `santoku.bench`
Simple benchmarking utility.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `bench` | `tag, fn, ...` | `result` | Benchmarks function execution with GC |

### `santoku.co`
Enhanced coroutine factory with tagged yields.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `co` | `tag` | `module` | Returns tagged coroutine module with `create`, `resume`, `wrap`, `yield` |

### `santoku.env`
Environment and system utilities.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `var` | `name, ...defaults` | `string/nil` | Gets environment variable with defaults |
| `interpreter` | `[include_args]` | `string, ...` | Gets interpreter command line |
| `searchpath` | `name, path, [sep], [rep]` | `path/nil` | Searches for file in path |

### `santoku.error`
Enhanced error handling with structured errors.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `error` | `...` | `nil` | Raises structured error |
| `assert` | `ok, ...` | `ok, ...` | Enhanced assert with structured errors |
| `pcall` | `fn, ...` | `ok, ...` | Protected call with structured errors |
| `xpcall` | `fn, handler` | `ok, ...` | Protected call with error handler |
| `wrapok` | `fn` | `function` | Wraps function to convert ok-style to errors |
| `wrapnil` | `fn` | `function` | Wraps function to convert nil to errors |
| `checkok` | `ok, ...` | `...` | Checks ok-style returns |
| `checknil` | `value, ...` | `value` | Checks for nil and converts to error |

### `santoku.functional`
Functional programming utilities and operator binding.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `bind` | `fn, ...` | `function` | Partially applies arguments |
| `maybe` | `fn` | `function` | Creates maybe-style error handling |
| `compose` | `a, b` | `function` | Function composition |
| `sel` | `fn, n` | `function` | Selects nth argument before calling |
| `take` | `fn, n` | `function` | Takes first n arguments |
| `choose` | `cond, true_fn, false_fn, ...` | `result` | Conditional function selection |
| `id` | `...` | `...` | Identity function |
| `noop` | `()` | `nil` | No-operation function |
| `const` | `x` | `function` | Returns constant function |
| `get` | `property` | `function` | Property getter |
| `tget` | `table` | `function` | Table-specific getter |
| `set` | `property, value` | `function` | Property setter |
| `tset` | `table, value` | `function` | Table-specific setter |

Also exports bound versions of all operators from `santoku.op` module.

### `santoku.geo`
Geographic and geometric calculations.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `distance` | `point1, point2` | `number` | Euclidean distance |
| `earth_stereo` | `point, origin` | `x, y` | Stereographic projection |
| `earth_distance` | `point1, point2` | `number` | Great circle distance (km) |
| `rotate` | `point, origin, angle` | `x, y` | Rotates point around origin |
| `angle` | `point1, point2` | `number` | Angle between points |
| `bearing` | `point1, point2` | `number` | Geographic bearing |

### `santoku.inherit`
Metatable and inheritance utilities.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `pushindex` | `table, index` | `table` | Pushes index onto metatable chain |
| `popindex` | `table` | `table` | Pops index from metatable chain |
| `getindex` | `table` | `index/nil` | Gets __index from metatable |
| `setindex` | `table, index` | `table` | Sets __index on metatable |
| `hasindex` | `table, index` | `boolean` | Checks if index exists in chain |

### `santoku.iter`
Iterator creation and functional operations.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `once` | `fn` | `iterator` | Creates single-call iterator |
| `singleton` | `value` | `iterator` | Single-value iterator |
| `pairs` | `table` | `iterator` | Enhanced pairs iterator |
| `keys` | `table` | `iterator` | Iterator over keys |
| `vals` | `table` | `iterator` | Iterator over values |
| `ipairs` | `table` | `iterator` | Enhanced ipairs iterator |
| `ikeys` | `table` | `iterator` | Iterator over indices |
| `ivals` | `table` | `iterator` | Iterator over array values |
| `map` | `fn, iterator` | `iterator` | Maps function over iterator |
| `filter` | `fn, iterator` | `iterator` | Filters iterator |
| `flatten` | `iterator` | `iterator` | Flattens nested iterators |
| `chain` | `iter1, iter2` | `iterator` | Chains iterators |
| `paste` | `value, iterator` | `iterator` | Pastes value before each element |
| `tabulate` | `iterator` | `table` | Converts to table |
| `sum` | `iterator` | `number` | Sums numeric iterator |
| `count` | `iterator` | `number` | Counts elements |
| `min` | `iterator` | `value` | Minimum value |
| `max` | `iterator` | `value` | Maximum value |
| `mean` | `iterator` | `number` | Arithmetic mean |
| `set` | `iterator, [table]` | `table` | Creates set from iterator |
| `interleave` | `value, iterator` | `iterator` | Interleaves value between elements |
| `deinterleave` | `iterator` | `iterator` | Removes every other element |
| `async` | `iterator` | `async_iterator` | Converts to async iterator |
| `each` | `fn, iterator` | `nil` | Applies function to each |
| `reduce` | `acc_fn, init, iterator` | `value` | Reduces with accumulator |
| `collect` | `iterator, [table], [start]` | `table` | Collects into array |
| `find` | `predicate, iterator` | `value` | Finds first match |
| `zip` | `iter1, iter2` | `iterator` | Zips two iterators |
| `first` | `iterator` | `value` | First element |
| `last` | `iterator` | `value` | Last element |
| `tail` | `iterator` | `iterator` | Skips first element |
| `butlast` | `iterator` | `iterator` | Excludes last element |
| `drop` | `n, iterator` | `iterator` | Drops first n elements |
| `take` | `n, iterator` | `iterator` | Takes first n elements |
| `range` | `start, [end], [delta], [interval]` | `iterator` | Numeric range iterator |
| `spread` | `iterator` | `...` | Spreads as arguments |

### `santoku.lua`
Lua language utilities and compatibility.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `loadstring` | `code, [env]` | `function, error` | Enhanced loadstring with environment |
| `setfenv` | `fn, env` | `function` | Sets function environment |
| `getfenv` | `fn` | `table` | Gets function environment |
| `getupvalue` | `fn, name_or_index` | `value, name` | Gets function upvalue |
| `userdata` | `metatable` | `userdata` | Creates userdata with metatable |

### `santoku.num`
Numeric utilities and math extensions.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `trunc` | `n, [decimals]` | `number` | Truncates to decimal places |
| `atan` | `y, [x]` | `number` | Enhanced atan with atan2 |
| `mavg` | `alpha` | `function` | Creates moving average function |
| `round` | `n, [multiple]` | `number` | Rounds to nearest multiple |

Includes all functions from standard `math` module.

### `santoku.op`
Operator functions for functional programming.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `eq` | `a, b` | `boolean` | Equality operator |
| `neq` | `a, b` | `boolean` | Inequality operator |
| `and` | `a, b` | `value` | Logical and |
| `or` | `a, b` | `value` | Logical or |
| `lt` | `a, b` | `boolean` | Less than |
| `gt` | `a, b` | `boolean` | Greater than |
| `lte` | `a, b` | `boolean` | Less than or equal |
| `gte` | `a, b` | `boolean` | Greater than or equal |
| `add` | `a, b` | `number` | Addition |
| `sub` | `a, b` | `number` | Subtraction |
| `mul` | `a, b` | `number` | Multiplication |
| `div` | `a, b` | `number` | Division |
| `mod` | `a, b` | `number` | Modulo |
| `not` | `a` | `boolean` | Logical not |
| `neg` | `a` | `number` | Numeric negation |
| `exp` | `a, b` | `number` | Exponentiation |
| `len` | `a` | `number` | Length operator |
| `cat` | `a, b` | `string` | String concatenation |
| `call` | `fn, ...` | `...` | Function call |

### `santoku.profiler`
Function-level performance profiling.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `profiler` | `()` | `function` | Creates profiling function returning report generator |

### `santoku.random`
Random number and data generation.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `seed` | `[time]` | `nil` | Seeds random generator |
| `str` | `length, [min_char], [max_char]` | `string` | Random string |
| `num` | `[min], [max]` | `number` | Random number |
| `norm` | `()` | `number` | Normal distribution random |
| `alnum` | `length` | `string` | Alphanumeric string |
| `options` | `params, [each_fn], [unique], [chunk_size]` | `iterator` | Random combinations |

#### C Extension: `santoku.random.fast`
| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `fast_random` | `()` | `integer` | Fast random number using MCG algorithm |
| `fast_normal` | `mean, variance` | `number` | Normal distribution using Box-Muller |
| `fast_max` | - | `constant` | Maximum value (UINT32_MAX) |

### `santoku.serialize`
Lua value serialization.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `serialize` | `value, [minify], [seen]` | `string` | Serializes value to Lua code |
| `serialize_table_contents` | `table, [minify], [seen]` | `string` | Serializes table contents only |

Module is callable: `serialize(value)`

### `santoku.string`
Extended string manipulation.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `splits` | `str, pattern, [delim], [start], [end]` | `iterator` | Splits string by pattern |
| `matches` | `str, pattern, [delim], [start], [end]` | `iterator` | Extracts pattern matches |
| `count` | `text, pattern, [start]` | `number` | Counts pattern occurrences |
| `parse` | `str, pattern` | `table` | Parses with named captures |
| `interp` | `string, table` | `string` | String interpolation |
| `quote` | `str, [quote_char], [escape_char]` | `string` | Quotes string |
| `unquote` | `str, [quote_char], [escape_char]` | `string` | Unquotes string |
| `startswith` | `str, pattern` | `boolean` | Tests prefix |
| `endswith` | `str, pattern` | `boolean` | Tests suffix |
| `escape` | `str` | `string` | Escapes regex special characters |
| `unescape` | `str` | `string` | Unescapes regex characters |
| `printf` | `format, ...` | `nil` | Formatted printing |
| `printi` | `string, table` | `nil` | Print with interpolation |
| `trim` | `str, [left_pattern], [right_pattern]` | `string` | Trims whitespace/patterns |
| `isempty` | `str` | `boolean` | Tests if empty or whitespace |
| `stripprefix` | `str, prefix` | `string` | Removes prefix |
| `compare` | `a, b` | `number` | Length-aware comparison |
| `commonprefix` | `...` | `string` | Common prefix of strings |
| `format_number` | `n` | `string` | Formats with thousands separators |
| `to_query` | `params, [out]` | `string` | Converts to URL query string |
| `from_query` | `str, [out]` | `table` | Parses URL query string |

Includes all functions from standard `string` module.

#### C Extension: `santoku.string.base`
| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `to_hex` | `data` | `string` | Converts binary to hexadecimal |
| `from_hex` | `hex_string` | `string` | Converts hexadecimal to binary |
| `to_base64` | `data, [url_safe]` | `string` | Base64 encoding |
| `from_base64` | `base64_string, [url_safe]` | `string` | Base64 decoding |
| `to_base64_url` | `data` | `string` | URL-safe base64 encoding |
| `from_base64_url` | `base64_url_string` | `string` | URL-safe base64 decoding |
| `to_url` | `data` | `string` | URL encoding (percent encoding) |
| `from_url` | `url_string` | `string` | URL decoding |
| `number` | `string, start_index` | `number/nil` | Parses number from string |
| `equals` | `literal, chunk, start, end` | `boolean` | Substring equality check |

### `santoku.table`
Extended table manipulation.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `get` | `table, ...path` | `value` | Gets nested value by path |
| `set` | `table, ...path, value` | `table` | Sets nested value by path |
| `update` | `table, ...path, fn` | `table` | Updates nested value with function |
| `merge` | `table, ...sources` | `table` | Deep merges tables |
| `assign` | `table, ...sources` | `table` | Shallow assigns tables |
| `equals` | `table1, table2` | `boolean` | Deep equality comparison |
| `map` | `table, fn` | `table` | Maps function over values |
| `clear` | `table` | `table` | Clears all entries |

Includes all functions from standard `table` module.

### `santoku.test`
Test execution with error handling.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `test` | `tag, fn` | `nil` | Executes test with error reporting |

### `santoku.tracer`
Line-by-line execution tracing.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `tracer` | `()` | `function` | Creates tracing function returning stop function |

### `santoku.utc`
UTC time utilities.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `stopwatch` | `()` | `function` | Creates stopwatch returning (duration, total) |

#### C Extension: `santoku.utc.capi`
| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `date` | `[timestamp], [local], [table]` | `table` | Converts timestamp to date table |
| `time` | `[date_table], [subsecond]` | `number` | Converts date to timestamp or gets current time |
| `format` | `timestamp, format_string, [local], [bufsize]` | `string` | Formats timestamp using strftime |
| `shift` | `timestamp, offset, unit, [table]` | `integer` | Shifts timestamp by offset units |
| `trunc` | `[timestamp], unit` | `integer` | Truncates timestamp to unit boundary |

### `santoku.validate`
Value validation and type checking.

#### Type Checking Functions

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `isstring` | `value` | `boolean` | Checks if value is string |
| `isnumber` | `value` | `boolean` | Checks if value is number |
| `istable` | `value` | `boolean` | Checks if value is table |
| `isfunction` | `value` | `boolean` | Checks if value is function |
| `isuserdata` | `value` | `boolean` | Checks if value is userdata |
| `isboolean` | `value` | `boolean` | Checks if value is boolean |
| `isnil` | `value` | `boolean` | Checks if value is nil |
| `isnotnil` | `value` | `boolean` | Checks if value is not nil |
| `istrue` | `value` | `boolean` | Checks if value is true |
| `isfalse` | `value` | `boolean` | Checks if value is false |
| `isprimitive` | `value` | `boolean` | Checks for primitive type |
| `isarray` | `table` | `boolean` | Validates array structure |
| `isfile` | `value` | `boolean` | Checks if value is file handle |

#### Metamethod Checking Functions

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `haspairs` | `value` | `boolean` | Has __pairs metamethod |
| `hasipairs` | `value` | `boolean` | Has __ipairs metamethod |
| `hasnewindex` | `value` | `boolean` | Has __newindex metamethod |
| `hasindex` | `value` | `boolean` | Has __index metamethod |
| `haslen` | `value` | `boolean` | Has __len metamethod |
| `hastostring` | `value` | `boolean` | Has __tostring metamethod |
| `hasconcat` | `value` | `boolean` | Has __concat metamethod |
| `hascall` | `value` | `boolean` | Has __call metamethod |
| `hasadd` | `value` | `boolean` | Has __add metamethod |
| `hassub` | `value` | `boolean` | Has __sub metamethod |
| `hasmul` | `value` | `boolean` | Has __mul metamethod |
| `hasdiv` | `value` | `boolean` | Has __div metamethod |
| `hasmod` | `value` | `boolean` | Has __mod metamethod |
| `haspow` | `value` | `boolean` | Has __pow metamethod |
| `hasunm` | `value` | `boolean` | Has __unm metamethod |
| `haseq` | `value` | `boolean` | Has __eq metamethod |
| `hasne` | `value` | `boolean` | Has __ne metamethod |
| `haslt` | `value` | `boolean` | Has __lt metamethod |
| `hasle` | `value` | `boolean` | Has __le metamethod |
| `hasgt` | `value` | `boolean` | Has __gt metamethod |
| `hasge` | `value` | `boolean` | Has __ge metamethod |
| `hasmetatable` | `value, [metatable]` | `boolean` | Has specific metatable |

#### Value Comparison Functions

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `isequal` | `a, b` | `boolean` | Equality check |
| `isnotequal` | `a, b` | `boolean` | Inequality check |
| `lt` | `value, limit` | `boolean` | Less than limit |
| `gt` | `value, limit` | `boolean` | Greater than limit |
| `le` | `value, limit` | `boolean` | Less than or equal |
| `ge` | `value, limit` | `boolean` | Greater than or equal |
| `between` | `value, low, high` | `boolean` | Range validation |
| `matches` | `str, pattern` | `boolean` | Pattern matching |
| `notmatches` | `str, pattern` | `boolean` | Pattern not matching |
| `hasargs` | `...` | `boolean` | Checks if arguments provided |

#### C Extension: `santoku.validate.capi`
| Constant | Description |
|----------|-------------|
| `MT_FILEHANDLE` | Metatable reference for Lua file handles |

### `santoku.varg`
Variable argument manipulation.

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `tup` | `fn, ...` | `...` | Applies function to arguments |
| `len` | `...` | `number` | Argument count |
| `sel` | `index, ...` | `value` | Selects specific argument |
| `take` | `count, ...` | `...` | Takes first n arguments |
| `get` | `index, ...` | `value` | Gets argument at index |
| `set` | `index, value, ...` | `...` | Sets argument at index |
| `includes` | `value, ...` | `boolean` | Checks if value exists |
| `append` | `value, ...` | `...` | Appends value |
| `extend` | `fn, ...` | `...` | Extends with function result |
| `interleave` | `separator, ...` | `...` | Interleaves separator |
| `reduce` | `fn, ...` | `value` | Reduces arguments |
| `tabulate` | `...` | `table` | Converts to table |
| `filter` | `predicate, ...` | `...` | Filters arguments |
| `reverse` | `...` | `...` | Reverses argument order |
| `each` | `fn, ...` | `nil` | Applies function to each |
| `map` | `fn, ...` | `...` | Maps function over arguments |
| `call` | `...` | `...` | Calls each as function |

Module is callable: `varg(...)` returns `tup(...)`

## Special Modules

### `santoku.autoserialize`
Automatically replaces global `print` function to serialize arguments.

### `santoku.profile`
Enables automatic profiling via garbage collection hooks. No direct exports.

### `santoku.trace`
Enables automatic tracing via garbage collection hooks. No direct exports.

## C Header Files

### `santoku/execinfo.h`
Linux-specific signal handler for stack traces.

| Function | Description |
|----------|-------------|
| `tk_execinfo_handler(sig)` | Signal handler that prints stack traces with addr2line |
| `tk_execinfo_init()` | Constructor function that registers SIGSEGV and SIGABRT handlers |

Features:
- Automatic stack trace on segmentation faults and aborts
- Uses addr2line for symbol resolution
- Filters out unresolved symbols
- Makes paths relative to current working directory

### `santoku/lua/utils.h`
Comprehensive Lua C API utilities.

#### Hash Functions
| Function | Description |
|----------|-------------|
| `tk_lua_hash_string(s)` | Hash string using kh_str_hash_func |
| `tk_lua_hash_integer(s)` | Hash integer using kh_int64_hash_func |
| `tk_lua_hash_double(x)` | Hash double with -0.0 == +0.0 normalization |
| `tk_lua_hash_mix(x)` | Mix hash using multiplication |
| `tk_lua_hash_128(lo, hi)` | Hash 128-bit value |

#### Error Handling
| Function | Description |
|----------|-------------|
| `tk_lua_errno(L, err)` | Raise error from errno |
| `tk_lua_error(L, err)` | Raise error with message |
| `tk_lua_errmalloc(L)` | Raise malloc error |
| `tk_lua_verror(L, n, ...)` | Raise error with multiple strings |
| `tk_error(L, label, err)` | Raise labeled error |

#### Stack Manipulation
| Function | Description |
|----------|-------------|
| `tk_lua_absindex(L, i)` | Convert to absolute index |
| `tk_lua_ref(L, i)` | Create registry reference |
| `tk_lua_unref(L, r)` | Release registry reference |
| `tk_lua_deref(L, r)` | Push referenced value |
| `tk_lua_callmod(L, nargs, nret, mod, fn)` | Call module function |

#### Type Checking and Conversion
| Function | Description |
|----------|-------------|
| `tk_lua_checktype(L, i, name, t)` | Check value type |
| `tk_lua_checkboolean(L, i)` | Check and get boolean |
| `tk_lua_checkstring(L, i, name)` | Check and get string |
| `tk_lua_checkinteger(L, i, name)` | Check and get integer |
| `tk_lua_checkdouble(L, i, name)` | Check and get double |
| `tk_lua_checkunsigned(L, i, name)` | Check and get unsigned |
| `tk_lua_checkuserdata(L, i, mt, name)` | Check userdata with metatable |
| `tk_lua_checkposinteger(L, i)` | Check positive integer |
| `tk_lua_checkposdouble(L, i, name)` | Check positive double |

#### Optional Values
| Function | Description |
|----------|-------------|
| `tk_lua_optboolean(L, i, name, def)` | Optional boolean with default |
| `tk_lua_optstring(L, i, name, def)` | Optional string with default |
| `tk_lua_optnumber(L, i, name, def)` | Optional number with default |
| `tk_lua_optunsigned(L, i, name, def)` | Optional unsigned with default |
| `tk_lua_optposdouble(L, i, name, def)` | Optional positive double with default |

#### Field Access
| Function | Description |
|----------|-------------|
| `tk_lua_ftype(L, i, field)` | Get field type |
| `tk_lua_fchecktype(L, i, name, field, t)` | Check field type |
| `tk_lua_fcheckboolean(L, i, name, field)` | Check boolean field |
| `tk_lua_fcheckstring(L, i, name, field)` | Check string field |
| `tk_lua_fcheckinteger(L, i, name, field)` | Check integer field |
| `tk_lua_fcheckdouble(L, i, name, field)` | Check double field |
| `tk_lua_fcheckunsigned(L, i, name, field)` | Check unsigned field |
| `tk_lua_fcheckuserdata(L, i, field, mt)` | Check userdata field |
| `tk_lua_foptboolean(L, i, name, field, def)` | Optional boolean field |
| `tk_lua_foptstring(L, i, name, field, def)` | Optional string field |
| `tk_lua_foptnumber(L, i, name, field, def)` | Optional number field |
| `tk_lua_foptinteger(L, i, name, field, def)` | Optional integer field |
| `tk_lua_foptunsigned(L, i, name, field, def)` | Optional unsigned field |

#### Memory Management
| Function | Description |
|----------|-------------|
| `tk_malloc(L, s)` | Allocate memory with error handling |
| `tk_realloc(L, p, s)` | Reallocate memory with error handling |
| `tk_malloc_aligned(L, s, a)` | Allocate aligned memory |

#### File Operations
| Function | Description |
|----------|-------------|
| `tk_lua_fopen(L, fp, flag)` | Open file with error handling |
| `tk_lua_fclose(L, fh)` | Close file with error handling |
| `tk_lua_fwrite(L, data, size, memb, fh)` | Write to file with error handling |
| `tk_lua_fread(L, data, size, memb, fh)` | Read from file with error handling |
| `tk_lua_fseek(L, size, memb, fh)` | Seek in file with error handling |
| `tk_lua_fslurp(L, fh, len)` | Read entire file to buffer |
| `tk_lua_tmpfile(L)` | Create temporary file |
| `tk_lua_fmemopen(L, data, size, flag)` | Open memory as file |

#### Userdata and Metatables
| Function | Description |
|----------|-------------|
| `tk_lua_newuserdata(L, t, mt, fns, gc)` | Create userdata with metatable |
| `tk_lua_testuserdata(L, idx, tname)` | Test userdata type |
| `tk_lua_register(L, regs, nup)` | Register functions with upvalues |

#### Ephemeron Tables
| Function | Description |
|----------|-------------|
| `tk_lua_add_ephemeron(L, eph_key, idx_parent, idx_ephemeron)` | Add to ephemeron table |
| `tk_lua_get_ephemeron(L, eph_key, e)` | Get from ephemeron table |

#### Random Number Generation
| Function | Description |
|----------|-------------|
| `tk_fast_random()` | Fast MCG random number generator |
| `tk_fast_normal(mean, variance)` | Normal distribution random |

#### String Utilities
| Function | Description |
|----------|-------------|
| `tk_lua_streq(L, i, str)` | Check string equality |
| `tk_lua_checklstring(L, i, lp, name)` | Check and get string with length |
| `tk_lua_fchecklstring(L, i, lp, name, field)` | Check field string with length |
| `tk_lua_checkustring(L, i, name)` | Check string or light userdata |
| `tk_lua_optustring(L, i, name, d)` | Optional string or light userdata |

### `santoku/klib.h`
Auto-generated header file that includes various lightly modified klib components.

Includes:
- `khash.h` - Hash table implementation
- `kbtree.h` - B-tree implementation
- `ksort.h` - Sorting algorithms
- `kvec.h` - Dynamic array implementation
