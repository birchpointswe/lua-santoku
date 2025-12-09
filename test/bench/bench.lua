local bench = require("santoku.bench")
local rand = require("santoku.random")
local asy = require("santoku.async")

local asy_ipairs = asy.ipairs

local data = {}
for i = 1, 1000000 do
  data[i] = rand.num()
end

bench("for", function (d)
  local total = 0
  for i = 1, #d do
    total = total + d[i]
  end
  return total
end, data)

bench("ipairs", function (d)
  local total = 0
  for _, v in ipairs(d) do
    total = total + v
  end
  return total
end, data)

bench("asy.ipairs", function (d)
  return asy_ipairs(function (k, s, i, v, ud)
    return k(s, i, ud + v)
  end, d, 0)
end, data)
