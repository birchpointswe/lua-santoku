local co_create = coroutine.create
local co_resume = coroutine.resume

local arr = require("santoku.array")
local asort = arr.sort
local aoverlay = arr.overlay

local iter = require("santoku.iter")
local itpairs = iter.pairs
local imap = iter.map
local icollect = iter.collect

local str = require("santoku.string")
local sprintf = str.printf

local calls, total, this = {}, {}, {}

local getinfo = debug.getinfo
local sethook = debug.sethook
local concat = table.concat
local clock = os.clock

return function ()

  local done = false
  local namet = {}

  local function hook (ev)
    local i = getinfo(2, "Sln")
    local fn = concat(aoverlay(namet, 1, i.name or "(unknown)", i.short_src, i.linedefined), " ")
    if ev == 'call' then
      this[fn] = clock()
    elseif this[fn] then
      local time = clock() - this[fn]
      total[fn] = (total[fn] or 0) + time
      calls[fn] = (calls[fn] or 0) + 1
    end
  end

  local start = clock()

  sethook(hook, "cr")

  coroutine.create = function (...) -- luacheck: ignore
    local co = co_create(...)
    sethook(co, hook, "cr")
    return co
  end

  coroutine.wrap = function (...) -- luacheck: ignore
    local co = co_create(...)
    sethook(co, hook, "cr")
    return function (...)
      return co_resume(co, ...)
    end
  end

  local function report ()
    if done then
      return
    end
    local stats = asort(icollect(imap(function (fn, time)
      return { fn = fn, time = time, calls = calls[fn] }
    end, itpairs(total))), function (a, b)
      return a.time < b.time
    end)
    for i = 1, #stats do
      local d = stats[i]
      sprintf("%.4f\t%d\t%s\n", d.time, d.calls, d.fn)
    end
    sprintf("%.4f\tTotal\n", clock() - start)
    coroutine.create = co_create -- luacheck: ignore
    coroutine.resume = co_resume -- luacheck: ignore
    done = true
  end

  return report

end
