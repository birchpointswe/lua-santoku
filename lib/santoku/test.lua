-- local validate = require("santoku.validate")
-- local hascall = validate.hascall
-- local isstring = validate.isstring

local arr = require("santoku.array")
local apush = arr.push
local apop = arr.pop
local acat = arr.concat
local aspread = arr.spread

local vargs = require("santoku.varg")
local vinterleave = vargs.interleave
local vsel = vargs.sel
local vget = vargs.get

local traceback = debug.traceback
local exit = os.exit

local tags = {}

return function (tag, fn)
  -- assert(hascall(fn))
  -- assert(isstring(tag))
  apush(tags, tag)
  xpcall(fn, function (...)
    print()
    print(acat({ vinterleave(": ", aspread(tags)) }))
    print()
    print(vsel(2, ...))
    print()
    print(vget(1, ...))
    print(traceback())
    print()
    exit(1)
  end)
  apop(tags)
end
