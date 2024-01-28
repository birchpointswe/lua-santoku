local arr = require("santoku.array")
local acat = arr.concat

local varg = require("santoku.varg")
local vinterleave = varg.interleave
local vmap = varg.map

local _error = error

local function error (...)
  _error(acat({ vinterleave(": ", vmap(tostring, ...)) }))
end

local function check (ok, ...)
  if not ok then
    _error({ ... })
  else
    return ...
  end
end

local function exists (...)
  return check(... ~= nil, ...)
end

-- local subcheck
-- subcheck = function (o, fn)

--   local N = {}
--   local o0 = {}

--   o0.handler = fn or fun.bindl(compat.id, false)

--   N.error = M.error

--   N.check = function (_, ...)
--     return o.co.yield(o0, ...)
--   end

--   N.exists = function (_, ...)
--     return o.co.yield(o0, (...) ~= nil, ...)
--   end

--   N.wrap = M.wrap

--   N.handler = function (n, fn)
--     o0.handler = fn
--     return n
--   end

--   N.sub = function (_, fn)
--     return subcheck(o, fn)
--   end

--   return setmetatable(N, {
--     __call = N.check
--   })

-- end

-- local function _wrap (o, ...)
--   return vtup(function (...)
--     if not (...) or o.co.status(o.cor) == "dead" then
--       return ...
--     elseif vsel(3, ...) then
--       return _wrap(o, vsel(4, ...))
--     else
--       local o0 = vsel(2, ...)
--       return vtup(function (...)
--         if (...) then
--           return _wrap(o, vsel(2, ...))
--         else
--           return ...
--         end
--       end, o0.handler(vsel(4, ...)))
--     end
--   end, o.co.resume(o.cor, ...))
-- end

-- local function wrap (run)
--   local create, resume, yield, status = co()
--   local cor = create(run)
--   return _wrap(cor, resume, status, subcheck(yield))
-- end

return {
  error = error,
  check = check,
  exists = exists,
  -- wrap = wrap,
}
