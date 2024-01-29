local co_create = coroutine.create

local capi = require("santoku.capi")

local arr = require("santoku.array")
local asort = arr.sort

local iter = require("santoku.iter")
local itpairs = iter.tpairs
local imap = iter.map
local icollect = iter.collect

local str = require("santoku.string")
local sprintf = str.printf

local calls, total, this = {}, {}, {}

local function hook (ev)
  local i = debug.getinfo(2, "Sln")
  if i.what ~= 'Lua' then return end
  local fn = table.concat({ i.name or "(unknown)", i.short_src .. ":" .. i.linedefined }, " ")
  if ev == 'call' then
    this[fn] = os.clock()
  elseif this[fn] then
    local time = os.clock() - this[fn]
    total[fn] = (total[fn] or 0) + time
    calls[fn] = (calls[fn] or 0) + 1
  end
end

local start = os.clock()

debug.sethook(hook, "cr")

coroutine.create = function (...) -- luacheck: ignore
  local co = co_create(...)
  debug.sethook(co, hook, "cr")
  return co
end

coroutine.wrap = function (...) -- luacheck: ignore
  local co = co_create(...)
  debug.sethook(co, hook, "cr")
  return function (...)
    return coroutine.resume(co, ...)
  end
end

local function report ()
  local stats = asort(icollect(imap(function (fn, time)
    return { fn = fn, time = time, calls = calls[fn] }
  end, itpairs(total))), function (a, b)
    return a.time < b.time
  end)
  for i = 1, #stats do
    local d = stats[i]
    sprintf("%.4f\t%d\t%s\n", d.time, d.calls, d.fn)
  end
  sprintf("%.4f\tTotal\n", os.clock() - start)
end

-- NOTE: this allows report to be called on program exit
_G[capi.userdata({ __gc = report })] = true

return report
