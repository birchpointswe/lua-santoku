-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023 Birch Point SWE
local serialize = require("santoku.serialize") -- luacheck: ignore
local utc = require("santoku.utc")
local test = require("santoku.test")
local err = require("santoku.error")
local num = require("santoku.num")
local tbl = require("santoku.table")
local vdt = require("santoku.validate")

test("date", function ()
  local t = 1712554366
  local d = utc.date(t)
  err.assert(tbl.equals(d, {
    hour = 5,
    min = 32,
    wday = 2,
    day = 8,
    yday = 99,
    month = 4,
    sec = 46,
    year = 2024,
    isdst = false
  }))
end)

test("time", function ()
  local t = 1712554366
  local d = {
    hour = 5,
    min = 32,
    wday = 2,
    day = 8,
    yday = 99,
    month = 4,
    sec = 46,
    year = 2024,
    isdst = false
  }
  err.assert(vdt.isequal(t, utc.time(d)))
  err.assert(utc.time({ year = 1, month = 1, day = 1 }))
end)

test("shift", function ()
  local t = 1712554366;
  local d = utc.date(t)
  utc.shift(t, 1, "day", d)
  err.assert(tbl.equals(d, {
    hour = 5,
    min = 32,
    wday = 3,
    day = 9,
    yday = 100,
    month = 4,
    sec = 46,
    year = 2024,
    isdst = false
  }))
end)

test("trunc", function ()
  local t = 1712554366
  local d = utc.date(t)
  utc.trunc(t, "day", d)
  err.assert(tbl.equals(d, {
    hour = 0,
    min = 0,
    wday = 2,
    day = 8,
    yday = 99,
    month = 4,
    sec = 0,
    year = 2024,
    isdst = false
  }))
end)

test("format", function ()
  local s = utc.format(1712554366, "%Y-%m-%d")
  err.assert(vdt.isequal(s, "2024-04-08"))
end)

test("ticktock", function ()
  local tt = utc.ticktock()
  local a1 = tt("a")()
  local stop = tt("b")
  local a2 = tt("a")()
  local b1 = stop()
  err.assert(a1 >= 0 and a2 >= 0 and b1 >= 0)
  local stats, total = tt()
  err.assert(vdt.isequal(stats.a.count, 2))
  err.assert(vdt.isequal(stats.b.count, 1))
  err.assert(stats.a.time >= 0 and total >= stats.a.time)
  err.assert(tt("z") ~= nil)
end)

test("subsec", function ()
  local t = utc.time(true)
  local tt = num.trunc(t, 0)
  t = t - tt
  err.assert(t > 0 and t < 1, "subsec fraction is zero")
end)

test("days_from_civil", function ()
  err.assert(vdt.isequal(utc.days_from_civil(1970, 1, 1), 0))
  err.assert(vdt.isequal(utc.days_from_civil(2024, 4, 8), 19821))
  err.assert(vdt.isequal(utc.days_from_civil(1969, 12, 31), -1))
  err.assert(vdt.isequal(utc.days_from_civil(2000, 2, 29), 11016))
end)

test("civil_from_days", function ()
  local y, m, d = utc.civil_from_days(0)
  err.assert(vdt.isequal(y, 1970) and vdt.isequal(m, 1) and vdt.isequal(d, 1))
  y, m, d = utc.civil_from_days(19821)
  err.assert(vdt.isequal(y, 2024) and vdt.isequal(m, 4) and vdt.isequal(d, 8))
  for z = -1000, 1000, 37 do
    y, m, d = utc.civil_from_days(z)
    err.assert(vdt.isequal(utc.days_from_civil(y, m, d), z))
  end
end)

test("weekday", function ()
  err.assert(vdt.isequal(utc.weekday(utc.days_from_civil(1970, 1, 1)), 4))
  err.assert(vdt.isequal(utc.weekday(utc.days_from_civil(2024, 4, 8)), 1))
  err.assert(vdt.isequal(utc.weekday(utc.days_from_civil(2024, 4, 7)), 0))
end)

test("local_offset", function ()
  local t = 1712554366
  local off = utc.local_offset(t)
  err.assert(vdt.isequal(off % 900, 0))
  err.assert(off >= -14 * 3600 and off <= 14 * 3600)
  err.assert(utc.local_offset() ~= nil)
end)

test("local_time inverts local date fields", function ()
  local t = num.trunc(utc.time(), 0)
  err.assert(vdt.isequal(utc.local_time(utc.date(t, true)), t))
  local fields = { year = 2026, month = 9, day = 2, hour = 18, min = 22, sec = 1 }
  local lt = utc.local_time(fields)
  local back = utc.date(lt, true)
  err.assert(vdt.isequal(back.year, 2026) and vdt.isequal(back.month, 9) and vdt.isequal(back.day, 2))
  err.assert(vdt.isequal(back.hour, 18) and vdt.isequal(back.min, 22) and vdt.isequal(back.sec, 1))
end)
