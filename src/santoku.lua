-- TODO: Asserts for arguments validation

-- TODO: Standardize error returns: in case of
-- error, return false, <enum>, <detail>

-- TODO: Across the board we could really use a
-- range generator

local utils = require("santoku.utils")

return utils.assign({
    tup = require("santoku.tuple"),
    co = require("santoku.co")
  },
  utils,
  require("santoku.err"),
  require("santoku.fs"),
  require("santoku.gen"),
  require("santoku.inherit"),
  require("santoku.op"),
  require("santoku.statistics"),
  require("santoku.string"),
  require("santoku.utils"),
  require("santoku.validation"))
