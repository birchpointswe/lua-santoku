local str = require("santoku.string")
local lfs = require("lfs")

local dir = lfs.currentdir() 
str.split(dir, "/"):each(function ()
  -- nothing
end)
