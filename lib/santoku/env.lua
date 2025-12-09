local arr = require("santoku.array")

local err = require("santoku.error")
local error = err.error

local gmatch = string.gmatch
local gsub = string.gsub
local sub = string.sub
local config = package.config
local io_open = io.open
local io_close = io.close
local tcat = table.concat
local os_getenv = os.getenv

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
    arr.push(ret, arg[i])
    i = i + 1
  end
  if args then
    while arg[i] do
      arr.push(ret, arg[i])
      i = i + 1
    end
  end
  return ret
end

local function var (name, ...)
  local val = os_getenv(name)
  local n = select("#", ...)
  if val then
    return val
  elseif n >= 1 then
    return (...)
  else
    error("Missing environment variable", name)
  end
end

local searchpath = package.searchpath or -- luacheck: ignore
  function (name, path, sep, rep)
    sep = gsub(sep or ".", "(%p)", "%%%1")
    rep = gsub(rep or sub(config, 1, 1), "(%%)", "%%%1")
    local pname = gsub(gsub(name, sep, rep), "(%%)", "%%%1")
    local msg = {}
    for subpath in gmatch(path, "[^;]+") do
      local fpath = gsub(subpath, "%?", pname)
      local f = io_open(fpath, "r")
      if f then
        io_close(f)
        return fpath
      end
      msg[#msg+1] = "\n\tno file '" .. fpath .. "'"
    end
    return nil, tcat(msg)
  end

return {
  var = var,
  interpreter = interpreter,
  searchpath = searchpath
}
