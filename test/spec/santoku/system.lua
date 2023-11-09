local assert = require("luassert")
local test = require("santoku.test")
local sys = require("santoku.system")

test("system", function ()

  test("pread", function ()

    test("should provide a chunked iterator for a forked processes stout and stderr", function ()

      local ok, iter = sys.pread("sh", "-c", "echo a; echo b >&2; exit 1")

      assert.equals(true, ok, iter)

      assert.same({
        { "stdout", "a\n", n = 2 },
        { "stderr", "b\n", n = 2 },
        { "exit", "exited", 1, n = 3},
        n = 3
      }, iter:vec())

    end)

  end)

  test("sh", function ()

    test("should provide a line-buffered iterator for a forked processes stout", function ()

      local ok, iter = sys.sh("sh", "-c", "echo a; echo b; exit 0")

      assert.equals(true, ok, iter)

      assert.same({
        { true, "a", n = 2 },
        { true, "b", n = 2 },
        n = 2
      }, iter:vec())

    end)

    test("should work with longer outputs", function ()

      local ok, iter = sys.sh("sh", "-c", "echo the quick brown fox; echo jumped over the lazy dog; exit 0")

      assert.equals(true, ok, iter)

      assert.same({
        { true, "the quick brown fox", n = 2 },
        { true, "jumped over the lazy dog", n = 2 },
        n = 2
      }, iter:vec())

    end)

  end)
end)
