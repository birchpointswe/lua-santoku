local vec = require("santoku.vector")
local plist = require("pl.List")

collectgarbage("stop")

local run = function(label, fn)

  collectgarbage("collect")
  local sm = collectgarbage("count")
  local st = os.clock()

  fn()

  local et = os.clock()
  local em = collectgarbage("count")

  print(label .. " time", et - st)
  print(label .. " mem", em - sm)

end

run("plist", function ()
  local l = plist.new()
  for i = 1, 1000000 do
    -- l:extend({ i, i +1, i +2, i +3, n = 3 })
    l:push(i)
  end
end)

run("vector", function ()
  local l = vec()
  for i = 1, 1000000 do
    l:append(i)
  end
end)

run("table", function ()
  local t = {}
  for i = 1, 1000000 do
    t[i] = i
  end
end)
