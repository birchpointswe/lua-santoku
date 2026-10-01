-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023 Birch Point SWE
local tbl = require("santoku.table")
local num = require("santoku.num")
local capi = require("santoku.utc.capi")

local floor = num.floor

local function days_from_civil (y, m, d)
  y = m <= 2 and y - 1 or y
  local era = floor((y >= 0 and y or y - 399) / 400)
  local yoe = y - era * 400
  local mm = m > 2 and (m - 3) or (m + 9)
  local doy = floor((153 * mm + 2) / 5) + d - 1
  local doe = yoe * 365 + floor(yoe / 4) - floor(yoe / 100) + doy
  return era * 146097 + doe - 719468
end

local function civil_from_days (z)
  z = z + 719468
  local era = floor((z >= 0 and z or z - 146096) / 146097)
  local doe = z - era * 146097
  local yoe = floor((doe - floor(doe / 1460) + floor(doe / 36524) - floor(doe / 146096)) / 365)
  local y = yoe + era * 400
  local doy = doe - (365 * yoe + floor(yoe / 4) - floor(yoe / 100))
  local mp = floor((5 * doy + 2) / 153)
  local d = doy - floor((153 * mp + 2) / 5) + 1
  local m = mp < 10 and (mp + 3) or (mp - 9)
  y = m <= 2 and (y + 1) or y
  return y, m, d
end

local function weekday (z)
  return (z % 7 + 4) % 7
end

local function local_offset (t)
  t = t or capi.time()
  return capi.time(capi.date(t, true)) - t
end

local function local_time (fields)
  local t = capi.time(fields)
  return t - local_offset(t)
end

return tbl.merge({
  days_from_civil = days_from_civil,
  civil_from_days = civil_from_days,
  weekday = weekday,
  local_offset = local_offset,
  local_time = local_time,
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
  end,

  ticktock = function ()
    local start = capi.time(true)
    local stats = {}
    return function (name)
      if name == nil then
        return stats, capi.time(true) - start
      end
      local t0 = capi.time(true)
      return function ()
        local dur = capi.time(true) - t0
        local e = stats[name]
        if not e then e = { time = 0, count = 0 }; stats[name] = e end
        e.time = e.time + dur
        e.count = e.count + 1
        return dur
      end
    end
  end
}, capi)
