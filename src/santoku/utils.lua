-- TODO: Some of these should be split into
-- a "common" module for brodly required
-- functions
-- TODO: I'm thinking we should switch the
-- library to use select instead of pack
-- directly: no pack, just use gen.args(...)
-- TODO: mergeWith, deep merge, etc, walk a
-- table

local M = {}

local unpack = unpack or table.unpack

-- TODO: Move to common?
M.pack = function (...)
  return { n = select("#", ...), ... }
end

-- TODO: Move to common?
M.unpack = function (...)
  local args = M.pack(...)
  if args.n == 1 then
    return unpack(args[1])
  end
  local n = 1
  local nargs = {}
  for i = 1, args.n do
    local t = args[i]
    local m
    if t.n ~= nil then
      m = t.n
    else
      m = #t
    end
    for j = 1, m do
      nargs[n] = t[j]
      n = n + 1
    end
  end
  return unpack(nargs, 1, n)
end

M.id = function (...)
  return ...
end

M.const = function (...)
  local val = M.pack(...)
  return function ()
    return M.unpack(val)
  end
end

M.narg = function (...)
  local idx = M.pack(...)
  return function (fn)
    return function (...)
      local args0 = M.pack(...)
      local args1 = {}
      for _, v in ipairs(idx) do
        table.insert(args1, args0[v])
      end
      return fn(M.unpack(args1))
    end
  end
end

M.nret = function (...)
  local idx = M.pack(...)
  return function (...)
    local args = M.pack(...)
    local rets = {}
    local ridx = 0
    for i = 1, idx.n do
      ridx = ridx + 1
      rets[ridx] = args[idx[i]]
    end
    rets.n = ridx
    return unpack(rets)
  end
end

M.interpreter = function (args)
  if arg == nil then
    return nil
  end
  local i_min = 0
  while arg[i_min] do
    i_min = i_min - 1
  end
  i_min = i_min + 1
  local ret = {}
  for i = i_min, 0 do
    table.insert(ret, arg[i])
  end
  if args then
    for i = 1, #arg do
      table.insert(ret, arg[i])
    end
  end
  return ret
end

-- TODO: simplify with recursion
-- TODO: Should we silently drop nil args?
M.compose = function (...)
  local fns = M.pack(...)
  return function(...)
    local vs = M.pack(...)
    for i = fns.n, 1, -1 do
      assert(type(fns[i]) == "function")
      vs = M.pack(fns[i](M.unpack(vs)))
    end
    return M.unpack(vs)
  end
end

-- TODO: allow composition
-- TODO: allow setting a nested value that
-- doesnt exist
M.lens = function (...)
  local keys = M.pack(...)
  return function (fn)
    fn = fn or M.id
    return function(t)
      if keys.n == 0 then
        return t, fn(t)
      else
        local t0 = t
        for i = 1, keys.n - 1 do
          if t0 == nil then
            return t, nil
          end
          t0 = t0[keys[i]]
        end
        local val = fn(t0[keys[keys.n]])
        t0[keys[keys.n]] = val
        return t, val
      end
    end
  end
end

M.getter = function (...)
  return M.compose(M.nret(2), M.lens(...)())
end

M.get = function (t, ...)
  return M.getter(...)(t)
end

M.setter = function (...)
  local keys = M.pack(...)
  return function (v)
    return M.lens(M.unpack(keys))(M.const(v))
  end
end

M.set = function (t, val, ...)
  return M.setter(...)(val)(t)
end

M.maybe = function (a, f, g)
  f = f or M.id
  g = g or M.const(a)
  if a then
    return f(a)
  else
    return g()
  end
end

M.choose = function (a, b, c)
  if a then
    return b
  else
    return c
  end
end

M.assign = function (t0, ...)
  local args = M.pack(...)
  for i = 1, args.n do
    local t1 = args[i]
    for k, v in pairs(t1) do
      t0[k] = v
    end
  end
  return t0
end

-- TODO: There MUST be a better way to do this,
-- but neither ipairs nor 'i = 0, #t' can manage
-- to handle both leading nils and intermixed
-- nils as expected.
M.extend = function (t0, ...)
  local n = 0
  for k, v in pairs(t0) do
    assert(type(k) == "number")
    if k > n then
      n = k
    end
  end
  local args = M.pack(...)
  for i = 1, args.n do
    local t1 = args[i]
    local m = 0
    for k, v in pairs(t1) do
      if type(k) == "number" then
        if k > m then
          m = k
        end
        t0[k + n] = v
      end
    end
    n = n + m
    m = 0
  end
  return t0
end

M.appender = function (...)
  local args = M.pack(...)
  return function (a)
    return M.extend(a, args)
  end
end

M.append = function (a, ...)
  return M.appender(...)(a)
end

return M
