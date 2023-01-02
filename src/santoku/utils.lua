-- TODO: Some of these should be split into
-- a "common" module for brodly required
-- functions

local M = {}

-- TODO: does this handle nils as expected? I
-- think we need to iterate numerically using
-- table.pack(...).n
-- TODO: does ipairs handle nils in table.pack
-- correctly?
M.extendarg = function (...)
  return table.unpack(M.extend({}, ...))
end

M.narg = function (...)
  local idx = table.pack(...)
  return function (fn)
    return function (...)
      local args0 = table.pack(...)
      local args1 = {}
      for _, v in ipairs(idx) do
        table.insert(args1, args0[v])
      end
      return fn(table.unpack(args1))
    end
  end
end

M.nret = function (...)
  local idx = table.pack(...)
  return function (...)
    local args = table.pack(...)
    local rets = {}
    for _, v in ipairs(idx) do
      table.insert(rets, args[v])
    end
    return table.unpack(rets)
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

M.id = function (...)
  return ...
end

M.compose = function (...)
  local args = table.pack(...)
  return M.ivals(args)
    :reduce(function(f, g)
      return function(...)
        return f(g(...))
      end
    end)
end

-- TODO: allow composition
M.lens = function (...)
  local keys = table.pack(...)
  return function (fn)
    fn = fn or M.id
    return function(t)
      if keys.n == 0 then
        return t, fn(t)
      else
        local t0 = t
        for i = 1, keys.n - 1 do
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

M.get = function (t, keys)
  return M.getter(table.unpack(keys))(t)
end

M.setter = function (...)
  local args = table.pack(...)
  return function (v)
    return M.lens(table.unpack(args))(M.const(v))
  end
end

M.set = function (t, keys, ...)
  return M.setter(table.unpack(keys))(...)(t)
end

M.maybe = function (a, f, g)
  f = f or M.id
  g = g or M.const(nil)
  if a then
    return f(a)
  else
    return g()
  end
end

M.const = function (...)
  local val = table.pack(...)
  return function ()
    return table.unpack(val)
  end
end

M.choose = function (a, b, c)
  if a then
    return b
  else
    return c
  end
end

M.assigner = function (...)
  local args = table.pack(...)
  return function (t0)
    for _, t1 in ipairs(args) do
      for k, v in pairs(t1) do
        t0[k] = v
      end
    end
    return t0
  end
end

M.assign = function (t0, ...)
  return M.assigner(...)(t0)
end

M.extender = function (...)
  local args = table.pack(...)
  return function (a)
    for _, t in ipairs(args) do
      for _, v in ipairs(t) do
        table.insert(a, v)
      end
    end
    return a
  end
end

M.extend = function (a, ...)
  return M.extender(...)(a)
end

M.appender = function (...)
  local args = table.pack(...)
  return function (a)
    return M.extend(a, args)
  end
end

M.append = function (a, ...)
  return M.appender(...)(a)
end

return M
