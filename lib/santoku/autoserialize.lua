-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023 Birch Point SWE
local arr = require("santoku.array")
local serialize = require("santoku.serialize")
local _print = _G.print
_G.print = function (...)
  local t = arr.map(arr.pack(...), serialize)
  return _print(arr.spread(t))
end
