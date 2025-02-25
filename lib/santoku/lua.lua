local lua = require("santoku.lua.lua")
local tbl = require("santoku.table")
local err = require("santoku.error")

local wrapnil = err.wrapnil
local tmerge = tbl.merge

local _getupvalue = debug.getupvalue
local _loadstring = wrapnil(loadstring) -- luacheck: ignore
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

local function loadstring (code, env)
  local fn = _loadstring(code)
  if env then
    setfenv(fn, env) -- luacheck: ignore
  end
  return fn
end

local function utc_offset ()
  local ts = os.time()
  local utc_date = os.date('!*t', ts)
  local utc_time = os.time(utc_date)
  local local_date = os.date('*t', ts)
  local local_time = os.time(local_date)
  return local_time - utc_time
end

local function utc_today ()
  local d = os.date("*t")
  d.hour = 0
  d.min = 0
  d.sec = 0
  return os.time(d) + utc_offset()
end

return tmerge({
  utc_offset = utc_offset,
  utc_today = utc_today,
  loadstring = loadstring,
  setfenv = setfenv,
  getfenv = getfenv,
  getupvalue = getupvalue,
}, lua)
