local arr = require("santoku.array")

local traceback = debug.traceback
local exit = os.exit

local tags = {}

return function (tag, fn)
  arr.push(tags, tag)
  xpcall(fn, function (...)
    print()
    print(arr.concat(arr.interleaved(tags, ": ")))
    print()
    print((select(2, ...)))
    print()
    print((...))
    print(traceback())
    print()
    exit(1)
  end)
  arr.pop(tags)
end
