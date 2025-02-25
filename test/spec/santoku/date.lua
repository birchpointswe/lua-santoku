local serialize = require("santoku.serialize") -- luacheck: ignore
local date = require("santoku.date") -- luacheck: ignore
local test = require("santoku.test")
-- local err = require("santoku.error")
-- local str = require("santoku.string")
-- local tbl = require("santoku.table")

test("date", function ()
  -- print("day", serialize({date.utc_trunc(date.utc_date(), "day")}))
  -- print("month", serialize({date.utc_trunc(date.utc_date(), "month")}))
  -- print("year", serialize({date.utc_trunc(date.utc_date(), "year")}))
end)

test("local", function ()
  -- local s = date.utc_time()
  -- local d = date.utc_date(s)
  -- print(str.interp("%year-%month-%day %hour:%min:%sec", d))
  -- s = date.utc_shift(d, 10, "day")
  -- print(str.interp("%year-%month-%day %hour:%min:%sec", d))
  -- local dl = date.utc_local(s)
  -- print(str.interp("%year-%month-%day %hour:%min:%sec", dl))
end)

-- local t = date.utc_time()
-- print(date.utc_format(t, "%c", false), date.utc_format(t, "%c", true))
