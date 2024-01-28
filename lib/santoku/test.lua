local compat = require("santoku.compat")
local hascall = compat.hasmeta.call
local isstring = compat.istype.string

local arr = require("santoku.array")
local apush = arr.push
local apop = arr.pop
local acat = arr.concat
local aspread = arr.spread

local vargs = require("santoku.varg")
local vinterleave = vargs.interleave
local vsel = vargs.sel
local vget = vargs.get

local tags = {}

return function (tag, fn)
  assert(hascall(fn))
  assert(isstring(tag))
  apush(tags, tag)
  xpcall(fn, function (...)
    print()
    print(acat({ vinterleave(": ", aspread(tags)) }))
    print()
    print(vsel(2, ...))
    print()
    print(vget(1, ...), debug.traceback())
    print()
    os.exit(1)
  end)
  apop(tags)
end
