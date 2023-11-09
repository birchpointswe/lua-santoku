local str = require("santoku.string")
local unistd = require("posix.unistd")

local dir = unistd.getcwd()
str.split(dir, "/"):each(function ()
  -- nothing
end)
