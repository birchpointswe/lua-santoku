local capi = require("santoku.capi")
local gen = require("santoku.gen")
local str = require("santoku.string")

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

local co_create = coroutine.create

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
  gen.pairs(total):map(function (fn, time)
    return { fn = fn, time = time, calls = calls[fn] }
  end):vec():sort(function (a, b)
    return a.time < b.time
  end):each(function (d)
    str.printf("%.4f\t%d\t%s\n", d.time, d.calls, d.fn)
  end)
  str.printf("%.4f\tTotal\n", os.clock() - start)
end

-- NOTE: this allows report to be called on program exit
_G[capi.userdata({ __gc = report })] = true

return report
