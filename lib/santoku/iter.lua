local validate = require("santoku.validate")
local hascall = validate.hascall

local fun = require("santoku.functional")
local noop = fun.noop

local arr = require("santoku.array")
local aoverlay = arr.overlay
local aspread = arr.spread

local varg = require("santoku.varg")
local vtup = varg.tup
local vsel = varg.sel

local function _reduce (acc, v, it, a, i, ...)
  if i == nil then
    return v
  elseif not v then
    return _reduce(acc, ..., it, a, it(a, i))
  else
    return _reduce(acc, acc(v, ...), it, a, it(a, i))
  end
end

local function reduce (acc, v, it, a, i)
  assert(hascall(acc))
  assert(hascall(it))
  return _reduce(acc, v, it, a, it(a, i))
end

local function _collect (a, n)
  a[#a + 1] = n
  return a
end

local function collect (it, a, i)
  assert(hascall(it))
  return reduce(_collect, {}, it, a, i)
end

local function head (it, a, i)
  assert(hascall(it))
  if i ~= nil then
    return vsel(2, it(a, i))
  end
end

local function _each (a, ...)
  a(...)
  return a
end

local function each (fn, it, a, i)
  assert(hascall(it))
  return reduce(_each, fn, it, a, i)
end

local function _map (fn, i, ...)
  if i ~= nil then
    return i, fn(...)
  end
end

-- TODO: do we need a closure?
local function map (fn, it, a, i)
  return function (a, i)
    return _map(fn, it(a, i))
  end, a, i
end

local function _filter (fn, it, a, i, ...)
  if i ~= nil then
    if fn(...) then
      return i, ...
    else
      return _filter(fn, it, a, it(a, i))
    end
  end
end

-- TODO: do we need a closure?
local function filter (fn, it, a, i)
  assert(hascall(fn))
  assert(hascall(it))
  return function (a, i)
    return _filter(fn, it, a, it(a, i))
  end, a, i
end

-- TODO: can we reduce the number of closures?
local function flatten (parent_it, parent_a, parent_i)
  local parent_i0, child_it, child_a, child_i
  local function _flatten (parent_a, parent_i)
    if parent_i == nil then
      return
    end
    if child_it == nil then
      parent_i0, child_it, child_a, child_i = parent_it(parent_a, parent_i)
      if parent_i0 == nil then
        return
      end
    end
    return vtup(function (child_i0, ...)
      if child_i0 == nil then
        child_it = nil
        return _flatten(parent_a, parent_i0)
      else
        child_i = child_i0
        return parent_i, ...
      end
    end, child_it(child_a, child_i))
  end
  return _flatten, parent_a, parent_i
end

-- TODO: Use coroutine tuples to keep nils?
-- TODO: Shouldn't the checks for #t == 0 and t[1] == nil be the same? How can
-- we get the length of a table excluding nils?
local function _interleave (v, it)
  local t = {}
  local interleaving = false
  return function (a, i)
    while true do
      if #t == 0 then
        aoverlay(t, 1, it(a, i))
        i = t[1]
      elseif t[1] == nil then
        return
      elseif not interleaving then
        interleaving = true
        return aspread(t)
      else
        interleaving = false
        aoverlay(t, 1, it(a, i))
        return t[1], v
      end
    end
  end
end

local function _deinterleave (it)
  local removing = false
  local function __deinterleave (a, i)
    if i ~= nil then
      if not removing then
        removing = true
        return it(a, i)
      else
        removing = false
        return __deinterleave(a, it(a, i))
      end
    end
  end
  return __deinterleave
end

local function interleave (v, it, a, i)
  return _interleave(v, it), a, i
end

local function deinterleave (it, a, i)
  return _deinterleave(it), a, i
end

local function single (v)
  return function (_, i)
    if i then
      return false, v
    end
  end, nil, true
end

local function once (fn)
  return function (_, i)
    if i then
      return false, fn()
    end
  end, nil, true
end

local function tail (it, a, i)
  return it, a, (it(a, i))
end

local function _key (k)
  return k
end

local function _val (_, v)
  return v
end

local function _anext (a, i)
  i = i + 1
  if a[i] ~= nil then
    return i, i, a[i]
  end
end

local function _tnext (a, k)
  k = next(a, k)
  if k ~= nil then
    return k, k, a[k]
  end
end

local function apairs (t)
  return _anext, t, 0
end

local function tpairs (t)
  return _tnext, t, nil
end

local function akeys (t)
  return map(_key, apairs(t))
end

local function avals (t)
  return map(_val, apairs(t))
end

local function tkeys (t)
  return map(_key, tpairs(t))
end

local function tvals (t)
  return map(_val, tpairs(t))
end

local function _async (each, final, it, a, i, ...)
  if i == nil then
    return final(true, i, ...)
  else
    return each(function (ok, ...)
      if ok then
        return _async(each, final, it, a, it(a, i))
      else
        return final(ok, ...)
      end
    end, i, ...)
  end
end

local function async (it, a, i)
  return function (each, final)
    assert(hascall(each))
    final = final or noop
    assert(hascall(final))
    return _async(each, final, it, a, it(a, i))
  end
end

local function wrap (it, a, i)
  return function ()
    return vtup(function (i0, ...)
      i = i0
      if i ~= nil then
        return ...
      end
    end, it(a, i))
  end
end

return {

  once = once,
  single = single,

  apairs = apairs,
  akeys = akeys,
  avals = avals,

  tpairs = tpairs,
  tkeys = tkeys,
  tvals = tvals,

  map = map,
  filter = filter,
  flatten = flatten,

  interleave = interleave,
  deinterleave = deinterleave,

  async = async,
  wrap = wrap,

  each = each,
  reduce = reduce,
  collect = collect,

  head = head,
  tail = tail,

}

-- TODO: Add append, extend, etc. functions for
-- basic generators by wrapping

-- M.range = function (...)
--   local args = tup(...)
--   assert(compat.istype.number((...)))
--   return M.gen(function (yield)
--     if tup.len(args()) >= 2 then
--       local s, e, m = args()
--       m = m or (s < e and 1 or -1)
--       for i = s, e, m do
--         yield(i)
--       end
--     elseif tup.len(args()) == 1 then
--       local e = (args())
--       if e > 0 then
--         for i = 1, e, 1 do
--           yield(i)
--         end
--       elseif e < 0 then
--         for i = -1, e, -1 do
--           yield(i)
--         end
--       end
--     end
--   end)
-- end

-- M.index = function (gen)
--   assert(M.isgen(gen))
--   local idx = 0
--   return M.gen(function (each)
--     return gen:each(function (...)
--       idx = idx + 1
--       return each(idx, ...)
--     end)
--   end)
-- end

-- M.paster = function (gen, ...)
--   local args = tup(...)
--   return gen:map(function (...)
--     return tup(...)(args())
--   end)
-- end

-- M.pastel = function (gen, ...)
--   local args = tup(...)
--   return gen:map(function (...)
--     return args(...)
--   end)
-- end

-- M.chunk = function (gen, n)
--   assert(M.isgen(gen))
--   assert(compat.istype.number(n))
--   assert(n > 0)
--   local chunk = vec()
--   return M.gen(function (yield)
--     gen:each(function(...)
--       if chunk.n >= n then
--         yield(chunk)
--         chunk = vec(...)
--       else
--         chunk:append(...)
--       end
--     end)
--     if chunk.n > 0 then
--       yield(chunk)
--     end
--   end)
-- end

-- M.discard = function (gen)
--   assert(M.isgen(gen))
--   return gen:each()
-- end

-- M.unpack = function (gen)
--   assert(M.isgen(gen))
--   return gen:tup()()
-- end

-- -- TODO: WHY DOES THIS NOT WORK!?
-- -- M.all = M.reducer(op["and"], true)
-- M.all = function (gen)
--   assert(M.isgen(gen))
--   return gen:reduce(function (a, n)
--     return a and n
--   end, true)
-- end

-- M.max = function (gen, ...)
--   assert(M.isgen(gen))
--   return gen:reduce(function(a, b)
--     if a > b then
--       return a
--     else
--       return b
--     end
--   end, ...)
-- end

-- M.min = function (gen, ...)
--   assert(M.isgen(gen))
--   return gen:reduce(function(a, b)
--     if a < b then
--       return a
--     else
--       return b
--     end
--   end, ...)
-- end

-- M.sum = function (gen)
--   assert(M.isgen(gen))
--   return gen:reduce(op.add)
-- end

-- M.concat = function (gen, delim)
--   return gen:vec():concat(delim)
-- end

-- M.last = function (gen)
--   assert(M.isgen(gen))
--   local last = tup()
--   gen:each(function (...)
--     last = tup(...)
--   end)
--   return last()
-- end

-- M.set = function (gen)
--   assert(M.isgen(gen))
--   return gen:reduce(function (s, v)
--     s[v] = true
--     return s
--   end, {})
-- end

-- M.append = function (gen, ...)
--   assert(M.isgen(gen))
--   local args = tup(...)
--   return gen:chain(M.gen(function (yield)
--     yield(args())
--   end))
-- end

-- M.take = function (gen, n)
--   assert(M.iscogen(gen))
--   assert(compat.istype.number(n))
--   assert(compat.ge(0, n))
--   return M.gen(function (yield)
--     while n > 0 and gen:step() do
--       n = n - 1
--       yield(gen.val())
--     end
--   end)
-- end

-- M.find = function (gen, fn, ...)
--   assert(M.iscogen(gen))
--   fn = fn or compat.id
--   while gen:step() do
--     if fn(gen.val(...)) then
--       return gen.val()
--     end
--   end
-- end

-- M.includes = function (gen, v)
--   assert(M.iscogen(gen))
--   return nil ~= gen:find(function (x)
--     return x == v
--   end)
-- end

-- M.group = function (gen, n)
-- 	assert(M.isgen(gen))
-- 	return gen:chunk(n):map(compat.unpack)
-- end

-- M.tabulate = function (gen, opts, ...)
--   if M.iscogen(gen) then
--     local keys, nkeys
--     if compat.istype.table(opts) then
--       keys, nkeys = tup(...), tup.len(...)
--     else
--       keys, nkeys = tup(opts, ...), 1 + tup.len(...)
--       opts = {}
--     end
--     local rest = opts.rest
--     local ret = tbl()
--     local idx = 0
--     while idx < nkeys and gen:step() do
--       idx = idx + 1
--       ret[select(idx, keys())] = gen.val()
--     end
--     if rest then
--       ret[rest] = gen:vec()
--     end
--     return ret
--   else
--     assert(M.isgen(gen))
--     return gen:reduce(function (a, k, v)
--       a[k] = v
--       return a
--     end, {})
--   end
-- end

-- M.slice = function (gen, start, num)
--   assert(M.iscogen(gen))
--   gen:take((start or 1) - 1):discard()
--   if num then
--     return gen:take(num)
--   else
--     return gen
--   end
-- end
