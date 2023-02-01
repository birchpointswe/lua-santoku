local fs = require("santoku.fs")
local vec = require("santoku.vector")
local fun = require("santoku.fun")
local op = require("santoku.op")

describe("santoku.fs", function ()

  describe("lines", function ()

    it("should return the correct number of lines", function ()

      local fp = "./test/spec/santoku/fs.tst1.txt"
      local ok, gen = fs.lines(fp)
      assert(ok)

      local lines = gen:vec()

      assert(lines.n == 4)
      assert.equals("line 1", lines[1])
      assert.equals("line 2", lines[2])
      assert.equals("line 3", lines[3])
      assert.equals("line 4", lines[4])

    end)

  end)

  describe("joinwith", function ()

    it("should handle nils", function ()

      local delim = "/"
      local result = fs.joinwith(delim, nil, "a", nil, "b")

      assert.equals("a/b", result)

    end)


  end)

  describe("dirname", function ()

    it("should return the directory name", function ()

      local p0 = "/opt/bin/sort"
      assert.equals("/opt/bin", fs.dirname(p0))

      local p1 = "stdio.h"
      assert.equals(".", fs.dirname(p1))

      local p2 = "../../test"
      assert.equals("../..", fs.dirname(p2))

    end)

  end)

  describe("basename", function ()

    it("should return the file name without directories", function ()

      local p0 = "/opt/bin/sort"
      assert.equals("sort", fs.basename(p0))

      local p1 = "stdio.h"
      assert.equals("stdio.h", fs.basename(p1))

    end)

  end)

  describe("files", function ()

    it("should list directory files", function ()
      local files = vec(
        "test/spec/santoku/fs/a/a.txt",
        "test/spec/santoku/fs/b/a.txt",
        "test/spec/santoku/fs/a/b.txt",
        "test/spec/santoku/fs/b/b.txt")
      local i = 0
      fs.files("test/spec/santoku/fs", { recurse = true })
        :each(function (k, ok, fp, mode)
          assert(ok)
          assert(files:find(fun.bindr(op.eq, fp)))
          assert(mode == "file")
          i = i + 1
          k()
        end)
        assert(i == 4)
    end)

  end)

  describe("splitexts", function ()

    it("should split a path into namme and extensions", function ()

      local p0 = "/opt/bin/sort.sh"
      assert.same({ name = "/opt/bin/sort", exts = { ".sh", n = 1} }, fs.splitexts(p0))

      local p1 = "stdio.tar.gz"
      assert.same({ name = "stdio", exts = { ".tar", ".gz", n = 2 } }, fs.splitexts(p1))

    end)

  end)

end)
