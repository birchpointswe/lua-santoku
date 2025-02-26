local serialize = require("santoku.serialize") -- luacheck: ignore
local utc = require("santoku.utc")
local test = require("santoku.test")
local err = require("santoku.error")
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

