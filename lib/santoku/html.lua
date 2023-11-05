-- NOTE: EXPERIMENTAL, NOT PRODUCTION READY

local vec = require("santoku.vector")

local M = {}

M.MT = {
  __call = function (_, ...)
    return M.render(...)
  end
}

M.selfclosed = vec(
  "area", "base", "br", "col", "embed",
  "hr", "img", "input", "link", "meta",
  "param", "source", "track", "wbr"
):reduce(function (a, n)
  a[n] = true
  return a
end, {})

M.compile = function (spec, result)

  if type(spec) ~= "table" then
    result:append(spec)
    return
  end

  local tag = spec[1]

  local selfclosed = M.selfclosed[tag]

  result:append("<", tag)

  for k, v in pairs(spec) do
    if type(k) == "string" then
      if type(v) == "table" then
        v = table.concat(v, " ")
      end
      result:append(" ", k, "=", "\"", v, "\"")
    end
  end

  if selfclosed then
    result:append("/>")
  else
    result:append(">")
    local i = 2
    while spec[i] do
      M.compile(spec[i], result)
      i = i + 1
    end
    result:append("</", tag, ">")
  end

end

M.render = function (spec)
  local result = vec()
  M.compile(spec, result)
  return result:concat()
end

return setmetatable(M, M.MT)
