-- local validate = require("santoku.validate")
-- local isnumber = validate.isnumber
-- local ge = validate.ge
-- local hascall = validate.hascall
-- local hasindex = validate.hasindex

local fun = require("santoku.functional")
local noop = fun.noop

local err = require("santoku.error")
local error = err.error

local op = require("santoku.op")
local add = op.add

local arr = require("santoku.array")
local clear = arr.clear
local overlay = arr.overlay
local spread = arr.spread

local varg = require("santoku.varg")
local tup = varg.tup

local _pairs = pairs

local function wrap (it, a, i)
  return function ()
    return tup(function (i0, ...)
      if i0 ~= nil then
        i = i0
        return i, ...
      end
    end, it(a, i))
  end
end

local function pairs (t)
  return wrap(_pairs(t))
end

local function _reduce (acc, v, it, i, ...)
  if i == nil then
    return v
  elseif not v then
    return _reduce(acc, i, it, it())
  else
    return _reduce(acc, acc(v, i, ...), it, it())
  end
end

local function reduce (acc, v, it)
  -- assert(hascall(acc))
  -- assert(hascall(it))
  return _reduce(acc, v, it, it())
end

local function collect (it, t, i)
  t = t or {}
  -- assert(hascall(it))
  -- assert(hasindex(t))
  i = i or #t + 1
  -- assert(isnumber(i))
  return clear(reduce(function (a, n)
    a[i] = n
    i = i + 1
    return a
  end, t, it), i)
end

local function first (it)
  -- assert(hascall(it))
  return it()
end

local function each (fn, it)
  -- assert(hascall(fn))
  -- assert(hascall(it))
  local function helper ()
    return tup(function (...)
      if ... ~= nil then
        fn(...)
        return helper()
      end
    end, it())
  end
  return helper()
end

local function map (fn, it)
  -- assert(hascall(fn))
  -- assert(hascall(it))
  return function ()
    return tup(function (...)
      if ... ~= nil then
        return fn(...)
      end
    end, it())
  end
end

local function paste (val, it)
  -- assert(hascall(it))
  return function ()
    return tup(function (...)
      if ... ~= nil then
        return val, ...
      end
    end, it())
  end
end

local function zip (a, b)
  -- assert(hascall(a))
  -- assert(hascall(b))
  return function ()
    return tup(function (...)
      if ... ~= nil then
        return ...
      end
    end, a(), b())
  end
end

local function chain (a, b)
  -- assert(hascall(a))
  -- assert(hascall(b))
  local it = a
  local function helper ()
    return tup(function (...)
      if ... ~= nil then
        return ...
      elseif it == a then
        it = b
        return helper()
      end
    end, it())
  end
  return helper
end

-- TODO: do we need a closure?
local function filter (fn, it)
  -- assert(hascall(fn))
  -- assert(hascall(it))
  local function helper ()
    return tup(function (...)
      if ... ~= nil then
        if fn(...) then
          return ...
        else
          return helper()
        end
      end
    end, it())
  end
  return helper
end

-- TODO: can we reduce the number of closures?
local function flatten (parent)
  -- assert(hascall(parent))
  local child
  local function helper ()
    if child == nil then
      child = parent()
      if child == nil then
        return
      end
      -- assert(hascall(child))
    end
    return tup(function (...)
      if ... == nil then
        child = nil
        return helper()
      else
        return ...
      end
    end, child())
  end
  return helper
end

local function last (it)
  -- assert(hascall(it))
  local t = {}
  each(function (...)
    overlay(t, 1, ...)
  end, it)
  return spread(t)
end

local function butlast (it)
  -- assert(hascall(it))
  local t
  local function helper ()
    if t == nil then
      t = { it() }
      return helper()
    elseif t[1] ~= nil then
      return tup(function (...)
        overlay(t, 1, it())
        if t[1] ~= nil then
          return ...
        end
      end, spread(t))
    end
  end
  return helper
end

-- TODO: This is more of an intersperse. Interleave would be taking multiple
-- iterators and interleaving their outputs
local function interleave (v, it)
  -- assert(hascall(it))
  local interleaving = false
  return butlast(function ()
    if interleaving then
      interleaving = false
      return v
    else
      interleaving = true
      return tup(function (...)
        if ... ~= nil then
          return ...
        end
      end, it())
    end
  end)
end

local function deinterleave (it)
  -- assert(hascall(it))
  local removing = false
  local function helper ()
    return tup(function (...)
      if ... ~= nil then
        if removing then
          removing = false
          return helper()
        else
          removing = true
          return ...
        end
      end
    end, it())
  end
  return helper
end

local function singleton (v)
  local done = false
  return function ()
    if not done then
      done = true
      return v
    end
  end
end

local function once (fn)
  -- assert(hascall(fn))
  local done = false
  return function ()
    if not done then
      done = true
      return fn()
    end
  end
end

local function tail (it)
  -- assert(hascall(it))
  if it() ~= nil  then
    return it
  else
    return noop
  end
end

local function take (n, it)
  -- assert(isnumber(n))
  -- assert(ge(n, 0))
  -- assert(hascall(it))
  return function ()
    if n ~= 0 then
      n = n - 1
      return it()
    end
  end
end

-- TODO: tabulate should support passing keys as additional arguments, such that
-- it.tabulate(it.ivals(1, 2, 3), "a", "b", "c") yields { a = 1, b = 2, c = 3 }
local function tabulate (it)
  -- assert(hascall(it))
  return reduce(function (a, k, v)
    a[k] = v
    return a
  end, {}, it)
end

local function set (it, t)
  t = t or {}
  -- assert(hascall(it))
  -- assert(hasindex(t))
  return reduce(function (a, n)
    a[n] = true
    return a
  end, t, it)
end

local function sum (it)
  -- assert(hascall(it))
  return reduce(add, 0, it)
end

local function count (it)
  -- assert(hascall(it))
  return reduce(function (a)
    return a + 1
  end, 0, it)
end

local function min (it)
  -- assert(hascall(it))
  return reduce(function (a, b)
    if not a or b < a then
      return b
    else
      return a
    end
  end, nil, it)
end

local function max (it)
  -- assert(hascall(it))
  return reduce(function (a, b)
    if not a or b > a then
      return b
    else
      return a
    end
  end, nil, it)
end

local function mean (it)
  -- assert(hascall(it))
  local c = 0
  return reduce(function (a, b)
    c = c + 1
    return a + b
  end, 0, it) / c
end

local function drop (n, it)
  -- assert(isnumber(n))
  -- assert(ge(n, 0))
  -- assert(hascall(it))
  local function helper1 ()
    return tup(function (...)
      if ... ~= nil then
        return ...
      end
    end, it())
  end
  local function helper0 ()
    if n == 0 then
      return helper1
    else
      return tup(function (...)
        if ... ~= nil then
          n = n - 1
          return helper0()
        else
          return noop
        end
      end, it())
    end
  end
  return helper0()
end

local function _key (k)
  return k
end

local function _val (_, v)
  return v
end

local function keys (t)
  return map(_key, pairs(t))
end

local function vals (t)
  -- assert(hasindex(t))
  return map(_val, pairs(t))
end

local function find (fn, it)
  local function helper (...)
    if ... ~= nil then
      if fn(...) then
        return ...
      else
        return helper(it())
      end
    end
  end
  return helper(it())
end

local function _async (each, final, it, ...)
  if ... == nil then
    return final(true, ...)
  else
    return each(function (ok, ...)
      if ok then
        return _async(each, final, it, it())
      else
        return final(ok, ...)
      end
    end, ...)
  end
end

local function async (it)
  -- assert(hascall(it))
  return function (each, final)
    -- assert(hascall(each))
    final = final or noop
    -- assert(hascall(final))
    return _async(each, final, it, it())
  end
end

local function range (...)
  local s, e, m
  if select("#", ...) == 1 then
    e = ...
    s = e < 0 and -1 or 1
    m = s
  else
    s, e, m = ...
    s = s or 1
    e = e or math.huge
    m = m or 1
    if s < e and m <= 0 then
      error("invalid range params: start < end but m <= 0", s, e, m)
    elseif s > e and m >= 0 then
      error("invalid range params: start > end but m >= 0", s, e, m)
    end
  end
  local i = s
  return function ()
    if (s < e and i > e) or (s > e and i < e) then
      return
    end
    local r = i
    i = i + m
    return r
  end
end

local function ipairs (t)
  return map(function (i)
    return i, t[i]
  end, range(#t))
end

local function ikeys (t)
  -- assert(hasindex(t))
  return map(_key, ipairs(t))
end

local function ivals (t)
  -- assert(hasindex(t))
  return map(_val, ipairs(t))
end

local function _spread (it, n)
  if n then
    return n, _spread(it, it())
  else
    return n
  end
end

local function spread (it)
  return _spread(it, it())
end

return {

  once = once,
  singleton = singleton,

  pairs = pairs,
  keys = keys,
  vals = vals,

  ipairs = ipairs,
  ikeys = ikeys,
  ivals = ivals,

  map = map,
  filter = filter,
  flatten = flatten,
  chain = chain,
  paste = paste,
  tabulate = tabulate,
  sum = sum,
  count = count,
  min = min,
  max = max,
  mean = mean,
  set = set,

  interleave = interleave,
  deinterleave = deinterleave,

  async = async,

  each = each,
  reduce = reduce,
  collect = collect,
  find = find,
  zip = zip,

  first = first,
  last = last,
  tail = tail,
  butlast = butlast,
  drop = drop,
  take = take,

  range = range,
  spread = spread,

}

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

-- M.spread = function (gen)
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

-- M.concat = function (gen, delim)
--   return gen:vec():concat(delim)
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

-- M.slice = function (gen, start, num)
--   assert(M.iscogen(gen))
--   gen:take((start or 1) - 1):discard()
--   if num then
--     return gen:take(num)
--   else
--     return gen
--   end
-- end
