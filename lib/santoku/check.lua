local tup = require("santoku.tuple")
local fun = require("santoku.fun")
local co = require("santoku.co")
local compat = require("santoku.compat")

local M = {}

M.error = function (_, ...)
  error(tup.concat(tup.interleave(": ", tup.map(tostring, ...))), 0)
end

M.check = function (_, ok, ...)
  if not ok then
    M:error(...)
  else
    return ...
  end
end

M.exists = function (_, ...)
  return M:check((...) ~= nil, ...)
end

local subcheck
subcheck = function (o, fn)

  local N = {}
  local o0 = {}

  o0.handler = fn or fun.bindl(compat.id, false)

  N.error = M.error

  N.check = function (_, ...)
    return o.co.yield(o0, ...)
  end

  N.exists = function (_, ...)
    return o.co.yield(o0, (...) ~= nil, ...)
  end

  N.wrap = M.wrap

  N.handler = function (n, fn)
    o0.handler = fn
    return n
  end

  N.sub = function (_, fn)
    return subcheck(o, fn)
  end

  return setmetatable(N, {
    __call = N.check
  })

end

M.wrap = function (_, run, ...)

  local o = {}
  o.co = co()
  o.cor = o.co.create(run)

  local args = tup(subcheck(o), ...)

  while true do
    local ret = tup(o.co.resume(o.cor, args()))
    if not ret() or o.co.status(o.cor) == "dead" then
      return ret()
    elseif tup.sel(3, ret()) then
      args = tup(tup.sel(4, ret()))
    else
      local _, o0 = ret()
      local hret = tup(o0.handler(tup.sel(4, ret())))
      if hret() then
        args = tup(tup.sel(2, hret()))
      else
        return hret()
      end
    end
  end

end

return setmetatable(M, { __call = M.check })
