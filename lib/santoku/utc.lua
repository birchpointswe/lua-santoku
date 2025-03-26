local tbl = require("santoku.table")
local capi = require("santoku.utc.capi")
return tbl.merge({
  stopwatch = function ()
    local start = capi.time(true)
    local last = start
    return function ()
      local now = capi.time(true)
      local total = now - start
      local duration = now - last
      last = now
      return duration, total
    end
  end
}, capi)
