local assert = require("luassert")
local test = require("santoku.test")

local geo = require("santoku.geo")
local num = require("santoku.num")

test("geo", function ()

  test("distance", function ()
    assert.equals(2, geo.distance({ x = 0, y = 0 }, { x = 0, y = 2 }))
    assert.equals(2, geo.distance({ x = 0, y = 0 }, { x = 2, y = 0 }))
    assert.equals(2 * math.sqrt(2), geo.distance({ x = 0, y = 0 }, { x = 2, y = 2 }))
  end)

  test("earth_distance", function ()
    local london = { lat = 51.5, lon = 0 }
    local arlington = { lat = 38.8, lon = -77.1 }
    assert.equals(5918185, num.trunc(geo.earth_distance(london, arlington), 0))
  end)

  test("angle", function ()
    assert.equals(135, geo.angle({ x = 0, y = 2 }, { x = 2, y = 0 }))
    assert.equals(90, geo.angle({ x = 0, y = 2 }, { x = 2, y = 2 }))
    assert.equals(270, geo.angle({ x = 0, y = 2 }, { x = -2, y = 2 }))
  end)

  test("bearing", function ()
    -- TODO
  end)

  -- TODO: Due to precision loss, we are
  -- truncating at 4 decimal places. Is this
  -- necessary?
  test("rotate", function ()
    local p
    p = geo.rotate({ x = 0, y = 2 }, { x = 0, y = 0 }, 90)
    p.x = num.trunc(p.x, 8)
    p.y = num.trunc(p.y, 8)
    assert.same({ x = 2, y = 0 }, p)
    p = geo.rotate({ x = 0, y = 2 }, { x = 0, y = 4 }, 90)
    p.x = num.trunc(p.x, 8)
    p.y = num.trunc(p.y, 8)
    assert.same({ x = -2, y = 4 }, p)
  end)

end)
