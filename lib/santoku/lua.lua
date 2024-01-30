local _lua = require("santoku.lua.lua")
local tbl = require("santoku.table")
local err = require("santoku.error")

local wrapnil = err.wrapnil
local tassign = tbl.assign

local _getupvalue = debug.getupvalue
local _load = wrapnil(load or loadstring) -- luacheck: ignore
local upvaluejoin = debug.upvaluejoin -- luacheck: ignore

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

local setfenv = setfenv or -- luacheck: ignore
  function (fn, env)
    local i = 1
    while true do
      local name = getupvalue(fn, i)
      -- NOTE: this will only be
      if name == "_ENV" then
        upvaluejoin(fn, i, (function() -- luacheck: ignore
          return env
        end), 1)
        break
      elseif not name then
        break
      end
      i = i + 1
    end
    return fn
  end

local getfenv = getfenv or -- luacheck: ignore
  function (fn)
    local i = 1
    local t = {}
    while true do
      local name, val = getupvalue(fn, i)
      if name == "_ENV" then
        return val
      elseif not name then
        return t
      else
        t[name] = val
      end
      i = i + 1
    end
  end

local function load (code, env)
  local fn = _load(code)
  if env then
    setfenv(fn, env) -- luacheck: ignore
  end
  return fn
end

return tassign({
  load = load,
  setfenv = setfenv,
  getfenv = getfenv,
  getupvalue = getupvalue,
}, _lua)
