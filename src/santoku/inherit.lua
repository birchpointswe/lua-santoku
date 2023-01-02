-- TODO: Basic inheritance logic

local utils = require("santoku.utils")

local M = {}

-- Add __index to t0 for all following args
M.inherit = function (t0, ...)
  utils.unimplemented("inherit")
end

-- Remove __index to t0 for all following args
M.uninherit = function (t0, ...)
  utils.unimplemented("uninherit")
end

-- Check if t0 inherits args
M.inherits = function (t0, ...)
  utils.unimplemented("inherits")
end

return M
