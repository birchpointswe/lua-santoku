local bench = require("santoku.bench")
local rand = require("santoku.random")
local asy = require("santoku.async")

local data = {}
for i = 1, 100000 do
  data[i] = rand.num()
end

bench("numeric for", function ()
  local total = 0
  for i = 1, #data do
    total = total + data[i]
  end
  return total
end)

bench("it.ivals", function ()
  local total = 0
  for v in it.ivals(data) do
    total = total + v
  end
  return total
end)

bench("asy.ivals", function ()
  return asy.ivals(data, function (k, t, i, v)
    if v == nil then
      return k(nil, t)
    else
      return k(v, t + v)
    end
  end, data, 0)
end)
