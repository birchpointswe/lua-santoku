local assert = require("luassert")
local test = require("santoku.test")

local err = require("santoku.err")

test("err", function ()

  test("pwrap", function ()

    test("check", function ()

      local ok, err = err.pwrap(function (check)
        check(false, "hi")
      end, function (tag, err)
        assert(tag == nil)
        assert(err == "hi")
        return false, err
      end)

      assert(ok == false)
      assert(err == "hi")

    end)

    test("check:exists", function ()

      test("handles functions that return nothing", function ()

        local fn = function () end

        local a, b, c = err.pwrap(function (check)

          check:tag("a"):exists(fn())
          assert(false, "shouldn't reach here")

        end, function (tag, result)

          assert(tag == "a")
          assert(result == nil)

        end)

        assert(a == nil)
        assert(b == nil)
        assert(c == nil)

      end)

    end)

    test("check:ok", function ()

      local a, b, c = err.pwrap(function (check)

        check:tag("a"):ok(false, "the error")
        assert(false, "shouldn't reach here")

      end, function (tag, result)

        assert(tag == "a")
        assert(result == "the error")

      end)

      assert(a == nil)
      assert(b == nil)
      assert(c == nil)

    end)

    test("check:ok (recover)", function ()

      local ok, result = err.pwrap(function (check)

        return check:tag("a"):ok(false, "the error")

      end, function (tag, result)

        assert(tag == "a")
        assert(result == "the error")
        return true, "b"

      end)

      assert(ok == true)
      assert(result == "b")

    end)

  end)

end)
