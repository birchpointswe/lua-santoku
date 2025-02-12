local collectgarbage = collectgarbage
local print = print
local clock = os.clock

return function (tag, fn, ...)
  collectgarbage()
  collectgarbage()
  local t0 = clock()
  local x = fn(...)
  local t1 = clock()
  print(tag, t1 - t0, x)
end
