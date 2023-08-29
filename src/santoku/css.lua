-- TODO: Media queries
-- TODO: The rest of the CSS3 spec

local vec = require("santoku.vector")

local function entity_mt (result)
  return {
    __div = function (a, b)
      if result.prev then
        result:extend(result.prev)
      end
      result:append(a.prefix, a.id)
      result.prev = vec(" > ", b.prefix, b.id, " ")
      result.prev.original = b
      return b
    end,
    __mul = function (a, b)
      if result.prev then
        result:extend(result.prev)
      end
      result:append(a.prefix, a.id)
      result.prev = vec(" ", b.prefix, b.id, " ")
      result.prev.original = b
      return b
    end,
    __add = function (a, b)
      if result.prev then
        result:extend(result.prev)
      end
      result:append(a.prefix, a.id, " ")
      result.prev = vec(" + ", b.prefix, b.id, " ")
      result.prev.original = b
      return b
    end,
    __mod = function (a, b)
      if result.prev then
        result:extend(result.prev)
      end
      if not result.prev or result.prev.original ~= a then
        result:append(a.prefix, a.id, " ")
      end
      result:append("{ ")
      for k, v in pairs(b) do
        result:append(k:gsub("_", "-"), ": ", v, "; ")
      end
      result:append("} ")
      result.prev = nil
      return b
    end
  }
end

local function add_nested (result, nesting, b)
  if nesting == 0 then
    return
  end
  result:append("{ ")
  for k, v in pairs(b) do
    if type(v) == "table" then
      result:append(k:gsub("_", "-"), " ")
      add_nested(result, nesting - 1, v)
    else
      result:append(k:gsub("_", "-"), ": ", v, "; ")
    end
  end
  result:append("} ")
end

local function atrule_mt (result, nesting)
  return {
    __mod = function (a, b)
      result:append("@", a.title, " ", a.id, " ")
      add_nested(result, nesting, b)
      return b
    end
  }
end

local function entity (prefix, title, mt, name, id, result, nesting)
  return setmetatable({
    title = title, prefix = prefix,
    name = name, id = id
  }, mt(result, nesting))
end

local function entities (prefix, title, mt, state, nesting)
  local ents = {}
  return setmetatable({}, {
    __index = function (_, k)
      if not ents[k] then
        ents[k] = entity(prefix, title, mt, k, tostring(state.n), state.result, nesting)
        state.names[k] = ents[k].id
        state.n = state.n + 1
      end
      return ents[k]
    end
  })
end

return function (n, names, result)
  local state = { n = n or 1, names = names or {}, result = result or vec() }
  local cs = entities(".", nil, entity_mt, state, 1)
  local is = entities("#", nil, entity_mt, state, 1)
  local ks = entities("@", "keyframes", atrule_mt, state, 2)
  return cs, is, ks, function ()
    return state.result:concat(), state.names, state.n
  end
end
