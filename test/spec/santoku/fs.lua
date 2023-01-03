local fs = require("santoku.fs")
local utils = require("santoku.utils")

describe("santoku.fs", function ()

  describe("joinwith", function ()

    local delim = "/"
    local parts =  { nil, "a", nil, "b"  }
    local result = fs.joinwith(delim, utils.unpack(parts))

    assert.equals("a/b", result)

  end)

end)
