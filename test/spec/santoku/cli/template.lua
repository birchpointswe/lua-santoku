local assert = require("luassert")
local test = require("santoku.test")
local sys = require("santoku.system")

test("santoku-cli", function ()

  test("template", function ()

    test("should allow stdin/stdout processing", function ()
      local toku = os.getenv("LUA") .. " bin/toku.lua"
      local ok, gen = sys.sh("echo '<% return \"hello\" %>' | ", toku, " template -f - -o -")
      assert.equals(true, ok, gen)
      assert.equals("hello", gen:co():head())
    end)

  end)

end)
