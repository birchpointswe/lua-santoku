local varg = require("santoku.varg")
local serialize = require("santoku.serialize")
local _print = _G.print
_G.print = function (...)
  return _print(varg.map(serialize, ...))
end
