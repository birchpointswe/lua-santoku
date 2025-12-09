local arr = require("santoku.array")
local serialize = require("santoku.serialize")
local unpack = unpack or table.unpack -- luacheck: ignore
local _print = _G.print
_G.print = function (...)
  local t = arr.map(arr.pack(...), serialize)
  return _print(unpack(t))
end
