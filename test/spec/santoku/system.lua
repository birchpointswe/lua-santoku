local assert = require("luassert")
local test = require("santoku.test")
local sys = require("santoku.system")

local unistd = require("posix.unistd")

test("system", function ()

  test("pread", function ()

    test("should provide a chunked iterator for a forked processes stout and stderr", function ()

      local ok, iter, children = sys.pread("sh", "-c", "echo a; echo b >&2; exit 1")

      assert.equals(true, ok, iter)
      assert.equals(1, children.n)

      local results = iter:vec():sort(function (a, b)
        return a[1] == "stdout" and b[1] ~= "stdout"
      end)

      assert.same({
        { "stdout", "a\n", children[1].pid, n = 3 },
        { "stderr", "b\n", children[1].pid, n = 3 },
        { "exit", "exited", 1, children[1].pid, n = 4},
        n = 3
      }, results)

    end)

  end)

  test("sh", function ()

    test("should provide a line-buffered iterator for a forked processes stout", function ()

      local ok, iter, children = sys.sh("sh", "-c", "echo a; echo b; exit 0")

      assert.equals(true, ok, iter)

      assert.same({
        { true, "a", children[1].pid, n = 3 },
        { true, "b", children[1].pid, n = 3 },
        n = 2
      }, iter:vec())

    end)

    test("should work with longer outputs", function ()

      local ok, iter, children = sys.sh("sh", "-c", "echo the quick brown fox; echo jumped over the lazy dog; exit 0")

      assert.equals(true, ok, iter)

      assert.same({
        { true, "the quick brown fox", children[1].pid, n = 3 },
        { true, "jumped over the lazy dog", children[1].pid, n = 3 },
        n = 2
      }, iter:vec())

    end)

    test("should support multi-processing", function ()

      local ok, iter, children = sys.sh({ jobs = 2 }, "sh", "-c", "echo a; echo b; exit 0")

      assert.equals(true, ok, iter)
      assert.equals(2, children.n)

      local results = iter:vec():sort(function (a, b)
        if a[3] == b[3] then
          return a[2] < b[2]
        else
          return a[3] < b[3]
        end
      end)

      assert.same({
        { true, "a", children[1].pid, n = 3 },
        { true, "b", children[1].pid, n = 3 },
        { true, "a", children[2].pid, n = 3 },
        { true, "b", children[2].pid, n = 3 },
        n = 4
      }, results)

    end)

    test("should support non-blocking polling", function ()

      local ok, iter, children = sys.sh({ block = false }, "sh", "-c", "echo a; sleep 2; echo b; exit 0")

      assert.equals(true, ok, iter)
      assert.equals(1, children.n)

      iter = iter:co()

      unistd.sleep(1)

      assert.equals(true, iter:step())
      assert.same({ true, "a", children[1].pid }, { iter.val() })

      assert.equals(true, iter:step())
      assert.same({ true, nil, children[1].pid }, { iter.val() })

      assert.equals(true, iter:step())
      assert.same({ true, nil, children[1].pid }, { iter.val() })

      assert.equals(true, iter:step())
      assert.same({ true, nil, children[1].pid }, { iter.val() })

      assert.equals(true, iter:step())
      assert.same({ true, nil, children[1].pid }, { iter.val() })

      unistd.sleep(2)

      assert.equals(true, iter:step())
      assert.same({ true, "b", children[1].pid }, { iter.val() })

      unistd.sleep(1)

      assert.equals(false, iter:step())

    end)

  end)
end)
