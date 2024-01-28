local arr = require("santoku.array")
local apush = arr.push

local varg = require("santoku.varg")
local vlen = varg.len

local err = require("santoku.error")
local error = err.error

local function interpreter (args)
  local arg = arg or {}
  local i_min = -1
  while arg[i_min] do
    i_min = i_min - 1
  end
  i_min = i_min + 1
  local ret = {}
  local i = i_min
  while i < 0 do
    apush(ret, arg[i])
    i = i + 1
  end
  if args then
    while arg[i] do
      apush(ret, arg[i])
      i = i + 1
    end
  end
  return ret
end

local function var (name, ...)
  local val = os.getenv(name)
  local n = vlen(...)
  if val then
    return val
  elseif n >= 1 then
    return (...)
  else
    error("Missing environment variable", name)
  end
end

return {
  var = var,
  interpreter = interpreter
}
