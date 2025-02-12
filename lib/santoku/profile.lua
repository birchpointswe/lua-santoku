local lua = require("santoku.lua")
local profiler = require("santoku.profiler")
_G[lua.userdata({ __gc = profiler() })] = true
