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
  local attr = spec[2]
  local ichild = 3

  local selfclosed = M.selfclosed[tag]

  if type(attr) ~= "table" or attr[1] then
    attr = nil
    ichild = 2
  end

  result:append("<", tag)

  if attr then
    for k, v in pairs(attr) do
      result:append(" ", k, "=", "\"", v, "\"")
    end
  end

  if selfclosed then
    result:append("/>")
  else
    result:append(">")
    while spec[ichild] do
      compile(spec[ichild], result)
      ichild = ichild + 1
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
