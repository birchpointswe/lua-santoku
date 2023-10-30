local assert = require("luassert")
local test = require("santoku.test")

local fs = require("santoku.fs")
local geo = require("santoku.geo.pdf")

test("geo/pdf", function ()

  test("extract_pdf_georefs", function ()
    local ok, data = fs.readfile("test/res/geo/map.pdf")
    assert(ok, data)
    local ok, data = geo.extract_pdf_georefs(data)
    assert(ok, data)
    assert.same(data, {
      boxes = {
        { { lat = 42.06176, lon = -74.25632, x = 14.4004, y = 575.9982 },
          { lat = 42.18867, lon = -74.25483, x = 14.4004, y = 777.62158 },
          { lat = 42.18679, lon = -74.00706, x = 50.37196, y = 777.62158 },
          { lat = 42.05989, lon = -74.00904, x = 50.37196, y = 575.9982 },
          n = 4 },
        { { lat = 39.99839, lon = -80.63405, x = 558.2555, y = 597.59928 },
          { lat = 45.28842, lon = -81.13471, x = 558.2555, y = 648.73801 },
          { lat = 45.38171, lon = -70.95252, x = 530.63594, y = 648.73801 },
          { lat = 40.07596, lon = -71.2841, x = 530.63594, y = 597.59928 },
          n = 4 },
        n = 2 },
      height = 8.5,
      width = 11.0
    })

  end)

end)
