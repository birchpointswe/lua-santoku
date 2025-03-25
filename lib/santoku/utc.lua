local tbl = require("santoku.table")
local num = require("santoku.num")
local capi = require("santoku.utc.capi")
return tbl.merge({
  stopwatch = function (...)
    local start = capi.time(true)
    local last = start
    local mavg = num.mavg(...)
    return function ()
      local now = capi.time(true)
      local total = now - start
      local duration = now - last
      local avg_duration = mavg(duration)
      last = now
      return duration, avg_duration, total
    end
  end
}, capi)
