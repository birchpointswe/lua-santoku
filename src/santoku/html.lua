local vec = require("santoku.vector")

local M = {}

M.selfclosed = vec(
  "area", "base", "br", "col", "embed",
  "hr", "img", "input", "link", "meta",
  "param", "source", "track", "wbr"
):reduce(function (a, n)
  a[n] = true
  return a
end, {})

local function compile (spec, result)

  if type(spec) ~= "table" then
    result:append(spec)
    return
  end

  local tag = spec[1]

  local selfclosed = M.selfclosed[tag]

  result:append("<", tag)

  for k, v in pairs(spec) do
    if type(k) == "string" then
      result:append(" ", k, "=", "\"", v, "\"")
    end
  end

  if selfclosed then
    result:append("/>")
  else
    result:append(">")
    local i = 2
    while spec[i] do
      compile(spec[i], result)
      i = i + 1
    end
    result:append("</", tag, ">")
  end

end

M.render = function (spec)
  local result = vec()
  compile(spec, result)
  return result:concat()
end

return setmetatable(M, {
  __call = function (_, ...)
    return M.render(...)
  end
})
