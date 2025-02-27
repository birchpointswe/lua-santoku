local lua = require("santoku.lua")
local tracer = require("santoku.tracer")
_G[lua.userdata({ __gc = tracer() })] = true
