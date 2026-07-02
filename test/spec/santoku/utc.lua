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
  local a1 = tt("a")()          -- one "a" measurement
  local stop = tt("b")          -- nest: start "b" while timing another "a"
  local a2 = tt("a")()
  local b1 = stop()
  err.assert(a1 >= 0 and a2 >= 0 and b1 >= 0)
  local stats, total = tt()
  err.assert(vdt.isequal(stats.a.count, 2))
  err.assert(vdt.isequal(stats.b.count, 1))
  err.assert(stats.a.time >= 0 and total >= stats.a.time)
  err.assert(tt("z") ~= nil)    -- tt(name) returns a stop closure
end)

test("subsec", function ()
  local t = utc.time(true)
  local tt = num.trunc(t, 0)
  t = t - tt
  err.assert(t > 0 and t < 1, "subsec fraction is zero")
end)
