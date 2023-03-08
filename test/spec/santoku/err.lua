local err = require("santoku.err")

describe("err", function ()

  describe("pwrap", function ()

    describe("check.exists", function ()

      it("handles functions that return nothing", function ()

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
