local assert = require("luassert")
local test = require("santoku.test")

local err = require("santoku.err")

test("err", function ()

  test("pwrap", function ()

    test("check.exists", function ()

      test("handles functions that return nothing", function ()

        local fn = function () end

        local a, b, c = err.pwrap(function (check)

          check.err("a", "b").exists(fn())
          assert(false, "shouldn't reach here")

        end, function (a, b, c)

          assert(a == "a")
          assert(b == "b")
          assert(c == nil)

        end)

        assert(a == nil)
        assert(b == nil)
        assert(c == nil)

      end)

    end)

  end)

end)
