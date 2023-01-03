local utils = require("santoku.utils")
local co = require("santoku.co")

local M = {}

M.iter = function (tbl, iter)
  tbl = tbl or {}
  local coroutine = co.make()
  return M.gen(coroutine.wrap(function ()
    local g, p, s = iter(tbl)
    while true do
      local vs = utils.pack(g(p, s))
      s = vs[1]
      if s == nil then
        break
      else
        coroutine.yield(utils.unpack(vs))
      end
    end
  end))
end

M.ipairs = function(t)
  return M.iter(t, ipairs)
end

M.pairs = function(t)
  return M.iter(t, pairs)
end

-- NOTE: We're dropping nil values here. We
-- can't do a simple map(nret(1)) because if
-- some values are nil the consumers of this
-- generator will stop early.
M.vals = function (t)
  local co = co.make()
  return M.gen(co.wrap(function ()
    for i, v in pairs(t) do
      if v ~= nil then
        co.yield(v)
      end
    end
  end))
end

M.keys = function (t)
  return M.map(M.pairs(t), utils.nret(1))
end

-- NOTE: We're dropping nil values here. We
-- can't do a simple map(nret(1)) because if
-- some values are nil the consumers of this
-- generator will stop early.
M.ivals = function (t)
  local co = co.make()
  return M.gen(co.wrap(function ()
    local max
    if t.n ~= nil then
      max = t.n
    else
      max = #t
    end
    for i = 1, max do
      local v = t[i]
      if v ~= nil then
        co.yield(v)
      end
    end
  end))
end

M.ikeys = function (t)
  return M.map(M.ipairs(t), utils.nret(1))
end

-- TODO: Is this the best way to do this?
-- TODO: What other metamethods can we override?
-- TODO: We should not assign all of M to the generator,
-- instead, only assign gen-related functions
-- TODO: Consider overloading operators for generators
M.gen = function (gen)
  return setmetatable({}, {
    __index = M,
    __call = gen,
  })
end

M.caller = function (...)
  local args = utils.pack(...)
  return function (f)
    return f(utils.unpack(args))
  end
end

M.call = function (f, ...)
  return M.caller(...)(f)
end

M.matcher = function (pat)
  return function (str)
    return M.gen(str:gmatch(pat))
  end
end

M.match = function (str, pat)
  return M.matcher(pat)(str)
end

M.reducer = function (acc, ...)
  local val1 = utils.pack(...)
  return function (gen)
    if val1.n == 0 then
      val1 = utils.pack(gen())
    end
    if val1.n == 0 then
      return nil
    end
    while true do
      local val2 = utils.pack(gen())
      if val2.n == 0 then
        return utils.unpack(val1)
      else
        val1 = utils.pack(acc(utils.extendarg(val1, val2)))
      end
    end
  end
end

M.reduce = function (gen, acc, ...)
  return M.reducer(acc, ...)(gen)
end

M.taker = function (n)
  return function (gen)
    local coroutine = co.make()
    return M.gen(coroutine.wrap(function ()
      while n > 0 do
        coroutine.yield(gen())
        n = n - 1
      end
    end))
  end
end

M.take = function (gen, n)
  return M.taker(n)(gen)
end

M.max = function (gen, def)
  return M.reduce(gen, function(a, b)
    if a > b then
      return a
    else
      return b
    end
  end, def)
end

M.flatten = function (gengen)
  local coroutine = co.make()
  return M.gen(coroutine.wrap(function ()
    while true do
      local gen = gengen()
      if gen == nil then
        break
      end
      while true do
        local val = utils.pack(gen())
        if val.n == 0 then
          break
        end
        coroutine.yield(utils.unpack(val))
      end
    end
  end))
end

M.collect = function (gen)
  return M.reduce(gen, function (a, ...)
    local vals = utils.pack(...)
    if vals.n <= 1 then
      return utils.append(a, vals[1])
    else
      -- NOTE: Design decision here: it might technically
      -- make more sense to provide vals here (a utils.pack()
      -- of the arguments, however in most uses users will
      -- expect zip to return a list of lists)
      return utils.append(a, { ... })
    end
  end, {})
end

M.filterer = function (fn, ...)
  fn = fn or utils.id
  local args = utils.pack(...)
  return function (gen)
    local coroutine = co.make()
    return M.gen(coroutine.wrap(function ()
      while true do
        local val = utils.pack(gen())
        if val.n == 0 then
          break
        end
        if fn(utils.extendarg(val, args)) then
          coroutine.yield(utils.unpack(val))
        end
      end
    end))
  end
end

M.filter = function (gen, fn, ...)
  return M.filterer(fn, ...)(gen)
end

M.mapper = function (fn, ...)
  fn = fn or utils.id
  local args = utils.pack(...)
  return function (gen)
    local coroutine = co.make()
    return M.gen(coroutine.wrap(function ()
      while true do
        local vals = utils.pack(gen())
        if vals.n == 0 then
          break
        else
          coroutine.yield(fn(utils.extendarg(vals, args)))
        end
      end
    end))
  end
end

M.map = function (gen, fn, ...)
  return M.mapper(fn, ...)(gen)
end

M.each = function (gen, fn)
  while true do
    local vals = utils.pack(gen())
    if vals.n == 0 then
      break
    else
      fn(utils.unpack(vals))
    end
  end
end

-- opts.mode defaults to "first"
-- opts.mode == "first" for stopping when first
--   generator ends
-- opts.mode == "longest" for stopping when
--   longest generator ends
-- opts.mode == "shortest" for stopping when
--   shortest generator ends
-- opts.mode == N for stopping after N iterations
-- invalid mode treated as "longest"
M.zipper = function (opts)
  local fn = (opts or {}).fn or utils.id
  local mode = (opts or {}).mode or "first"
  return function (...)
    local gens = utils.pack(...)
    local coroutine = co.make()
    local nb = 0
    return M.gen(coroutine.wrap(function ()
      while true do
        local vals = {}
        local nils = 0
        for i, gen in ipairs(gens) do
          local val = utils.pack(gen())
          if val.n == 0 then
            gens[i] = utils.const(nil)
            nils = nils + 1
            vals[i] = val
            if mode == "first" then
              break
            end
          else
            vals[i] = val
          end
        end
        nb = nb + 1
        if type(mode) == "number" and nb > mode then
          break
        elseif mode == "first" and vals[1].n == 0 then
          break
        elseif mode == "shortest" and nils > 0 then
          break
        elseif gens.n == nils then
          break
        else
          coroutine.yield(fn(utils.extendarg(utils.unpack(vals))))
        end
      end
    end))
  end
end

M.zip = function (...)
  return M.zipper()(...)
end

-- TODO: This name sucks
M.aller = function (fn, ...)
  fn = fn or utils.id
  local args = utils.pack(...)
  return function (gen)
    return M.reduce(gen, function (a, ...)
      return a and fn(utils.extendarg(args, utils.pack(...)))
    end)
  end
end

M.all = function (gen, ...)
  return M.aller(...)(gen)
end

M.tabulator = function (keys, opts)
  local rest = (opts or {}).rest
  return function (genVals)
    local t = M.ivals(keys)
      :zip(genVals)
      :reduce(function (a, k, v)
        a[k] = v
        return a
      end, {})
    if rest then
      t[rest] = genVals:collect()
    end
    return t
  end
end

M.tabulate = function (gen, keys, opts)
  return M.tabulator(keys, opts)(gen)
end

M.finder = function (...)
  local args = utils.pack(...)
  return function (gen)
    return gen:filter(utils.unpack(args)):head()
  end
end

M.find = function (gen, ...)
  return M.finder(...)(gen)
end

M.chain = function (...)
  local gens = utils.pack(...)
  local coroutine = co.make()
  return M.gen(coroutine.wrap(function ()
    for _, gen in ipairs(gens) do
      for v in gen do
        coroutine.yield(v)
      end
    end
  end))
end

M.equals = function (...)
  return M.zipper({
    fn = function (a, ...)
      local rest = utils.pack(...)
      for _, v in ipairs(rest) do
        if a ~= v then
          return false
        end
      end
      return true
    end,
    mode = "longest"
  })(...):all()
end

-- Split a string
--   opts.delim == false: throw out delimiters
--   opts.delim == true: keep delimiters as
--     separate tokens
--   opts.delim == "left": keep delimiters
--     concatenated to the left token
--   opts.delim == "right": keep delimiters
--     concatenated to the right token
--
-- TODO: allow splitting specific number of times from left or
-- right
--   opts.times: default == true
--   opts.times == true: as many as possible from left
--   opts.times == false: as many times as possible from right
--   opts.times > 0: number of times, starting from left
--   opts.times < 0: number of times, starting from right
M.splitter = function (pat, opts)
  opts = opts or {}
  local delim = opts.delim or false
  return function (str)
    local coroutine = co.make()
    return M.gen(coroutine.wrap(function ()
      local n = 0
      local ls = 0
      local stop = false
      while not stop do
        local s, e = str:find(pat, n)
        stop = s == nil
        if stop then
          s = #str + 1
        end
        if delim == true then
          coroutine.yield(str:sub(n, s - 1))
          if not stop then
            coroutine.yield(str:sub(s, e))
          end
        elseif delim == "left" then
          coroutine.yield(str:sub(n, e))
        elseif delim == "right" then
          coroutine.yield(str:sub(ls, s - 1))
        else
          coroutine.yield(str:sub(n, s - 1))
        end
        if stop then
          break
        else
          ls = s
          n = e + 1
        end
      end
    end))
  end
end

M.split = function (str, pat, opts)
  return M.splitter(pat, opts)(str)
end

M.slicer = function (start, num)
  start = start or 1
  return function (gen)
    local coroutine = co.make()
    return M.gen(coroutine.wrap(function ()
      local val
      while start > 1 do
        val = gen()
        if val == nil then
          return
        end
        start = start - 1
      end
      while num == nil or num > 0 do
        coroutine.yield(gen())
        if num ~= nil then
          num = num - 1
        end
      end
    end))
  end
end

M.slice = function (gen, start, num)
  return M.slicer(start, num)(gen)
end

M.head = function (gen)
  return gen()
end

M.picker = function (n)
  return function (gen)
    return M.slice(gen, n, 1):head()
  end
end

M.pick = function (gen, n)
  return M.picker(n, gen)
end

return M
