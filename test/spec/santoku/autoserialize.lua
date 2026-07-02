local test = require("santoku.test")

test("autoserialize replaces global print with a serializing print", function ()
  local real = _G.print
  require("santoku.autoserialize")
  assert(_G.print ~= real)
  _G.print = real
end)
