local vec = require("santoku.vector")

local function class (name, id, result)
  return setmetatable({
    name = name,
    id = id
  }, {
    __div = function (a, b)
      result:append(".", a.id, " > ", ".", b.id, " ")
      return b
    end,
    __mul = function (a, b)
      result:append(".", a.id, " ", ".", b.id, " ")
      return b
    end,
    __add = function (a, b)
      result:append(".", a.id, " + ", ".", b.id, " ")
      return b
    end,
    __mod = function (_, b)
      result:append("{ ")
      for k, v in pairs(b) do
        result:append(k:gsub("_", "-"), ": ", v, "; ")
      end
      result:append("} ")
      return b
    end
  })
end

local function classes (result, names)
  local n = 1
  local classes = {}
  return setmetatable({}, {
    __index = function (_, k)
      if not classes[k] then
        classes[k] = class(k, tostring(n), result)
        names[k] = classes[k].id
        n = n + 1
      end
      return classes[k]
    end
  })
end

return function (n, names, result)
  n = n or 1
  names = names or {}
  result = result or vec()
  local cs = classes(result, names, n)
  return cs, nil, nil, function ()
    return result:concat(), names, n
  end
end
