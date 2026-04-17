local lua = require("santoku.lua.lua")
local tbl = require("santoku.table")
local err = require("santoku.error")

local wrapnil = err.wrapnil

local _getupvalue = debug.getupvalue
local _loadstring = wrapnil(loadstring) -- luacheck: ignore

local function getupvalue (fn, name)
  if type(name) == "number" then
    local idx = name
    local n, val = _getupvalue(fn, idx)
    return n, val, idx
  else
    local idx = 1
    while true do
      local n, val = _getupvalue(fn, idx)
      if not n then break end
      if n == name then
        return n, val, idx
      end
      idx = idx + 1
    end
  end
end

local setfenv = setfenv -- luacheck: ignore
local getfenv = getfenv -- luacheck: ignore

local function loadstring (code, env)
  local fn = _loadstring(code)
  if env then
    setfenv(fn, env) -- luacheck: ignore
  end
  return fn
end

return tbl.merge({
  loadstring = loadstring,
  setfenv = setfenv,
  getfenv = getfenv,
  getupvalue = getupvalue,
}, lua)
