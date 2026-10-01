-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023 Birch Point SWE
local test = require("santoku.test")

local tbl = require("santoku.table")
local teq = tbl.equals

local geo = require("santoku.geo")
local gdistance = geo.distance
local gangle = geo.angle
local gbearing = geo.bearing
local grotate = geo.rotate

local num = require("santoku.num")
local trunc = num.trunc
local sqrt = num.sqrt

test("distance", function ()
  assert(2 == gdistance({ x = 0, y = 0 }, { x = 0, y = 2 }))
  assert(2 == gdistance({ x = 0, y = 0 }, { x = 2, y = 0 }))
  assert(2 * sqrt(2) == gdistance({ x = 0, y = 0 }, { x = 2, y = 2 }))
end)

test("angle", function ()
  assert(45 == gangle({ x = 0, y = 0 }, { x = 2, y = 2 }))
  assert(315 == gangle({ x = 0, y = 0 }, { x = -2, y = 2 }))
  assert(0 == gangle({ x = 0, y = 0 }, { x = 0, y = 2 }))
  assert(180 == gangle({ x = 0, y = 0 }, { x = 0, y = -2 }))
  assert(90 == gangle({ x = -2, y = 4 }, { x = 0, y = 4 }))
end)

test("bearing", function ()
  assert(90 == gbearing({ lat = 0, lon = 0 }, { lat = 0, lon = -90 }))
end)

test("rotate", function ()
  local p
  p = grotate({ x = 0, y = 2 }, { x = 0, y = 0 }, 90)
  p.x = trunc(p.x, 8)
  p.y = trunc(p.y, 8)
  assert(teq({ x = 2, y = 0 }, p))
  p = grotate({ x = 0, y = 2 }, { x = 0, y = 4 }, 90)
  p.x = trunc(p.x, 8)
  p.y = trunc(p.y, 8)
  assert(teq({ x = -2, y = 4 }, p))
end)
