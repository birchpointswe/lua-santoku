-- TODO: Asserts for arguments validation

-- TODO: Standardize error returns: in case of
-- error, return false, <enum>, <detail>

local utils = require("santoku.utils")

return utils.assign({},
  utils,
  require("santoku.co"),
  require("santoku.err"),
  require("santoku.fs"),
  require("santoku.gen"),
  require("santoku.inherit"),
  require("santoku.op"),
  require("santoku.statistics"),
  require("santoku.string"),
  require("santoku.utils"),
  require("santoku.validation"))
