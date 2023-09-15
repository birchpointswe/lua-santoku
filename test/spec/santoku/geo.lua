local assert = require("luassert")
local test = require("santoku.test")
local fs = require("santoku.fs")

local geo = require("santoku.geo")
local num = require("santoku.num")

local inspect = require("santoku.inspect")

test("geo", function ()

  test("distance", function ()
    assert.equals(2, geo.distance({ x = 0, y = 0 }, { x = 0, y = 2 }))
    assert.equals(2, geo.distance({ x = 0, y = 0 }, { x = 2, y = 0 }))
    assert.equals(2 * math.sqrt(2), geo.distance({ x = 0, y = 0 }, { x = 2, y = 2 }))
  end)

  test("earth_distance", function ()
    local london = { lat = 51.5, lon = 0 }
    local arlington = { lat = 38.8, lon = -77.1 }
    assert.equals(5918, num.trunc(geo.earth_distance(london, arlington), 0))
  end)

  test("angle", function ()
    assert.equals(45, geo.angle({ x = 0, y = 0 }, { x = 2, y = 2 }))
    assert.equals(315, geo.angle({ x = 0, y = 0 }, { x = -2, y = 2 }))
    assert.equals(0, geo.angle({ x = 0, y = 0 }, { x = 0, y = 2 }))
    assert.equals(180, geo.angle({ x = 0, y = 0 }, { x = 0, y = -2 }))
    assert.equals(90, geo.angle({ x = -2, y = 4 }, { x = 0, y = 4 }))
  end)

  test("bearing", function ()
    assert.equals(90, geo.bearing({ lat = 0, lon = 0 }, { lat = 0, lon = -90 }))
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

  test("extract_pdf_georefs", function ()
    local ok, data = fs.readfile("test/spec/santoku/map.pdf")
    assert(ok, data)
    local ok, data = geo.extract_pdf_georefs(data)
    assert(ok, data)
    assert.same(data, { boxes = { { { lat = 42.06176, lon = -74.25632, x = 14.4004, y = 575.9982 }, { lat = 42.18867, lon = -74.25483, x = 14.4004, y = 777.62158 }, { lat = 42.18679, lon = -74.00706, x = 50.37196, y = 777.62158 }, { lat = 42.05989, lon = -74.00904, x = 50.37196, y = 575.9982 }, n = 4 }, { { lat = 39.99839, lon = -80.63405, x = 558.2555, y = 597.59928 }, { lat = 45.28842, lon = -81.13471, x = 558.2555, y = 648.73801 }, { lat = 45.38171, lon = -70.95252, x = 530.63594, y = 648.73801 }, { lat = 40.07596, lon = -71.2841, x = 530.63594, y = 597.59928 }, n = 4 }, n = 2 }, height = 8.5, width = 11.0 })

  end)

  -- test("extract_pdf_georefs", function ()
  --   local ok, data = fs.readfile("test/spec/santoku/map.pdf")
  --   assert(ok)
  --   fs.writefile("test/spec/santoku/map.extracted.bin", geo.extract_pdf_georefs(data))
  --   -- print(geo.extract_pdf_georefs(data))
  -- end)

end)
