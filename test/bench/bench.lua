local list = require("santoku.list")
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
    l:push(i)
  end
end)

run("plist", function ()
  local l = plist.new()
  for i = 1, 1000000 do
    l:append(i)
  end
end)

run("list", function ()
  local l = list.empty
  for i = 1, 1000000 do
    l = list.push(l, i)
  end
end)

run("table", function ()
  local t = {}
  for i = 1, 1000000 do
    t[i] = i
  end
end)

run("table", function ()
  local t = {}
  for i = 1, 1000000 do
    table.insert(t, i)
  end
end)
