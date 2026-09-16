local test = require("santoku.test")
local env = require("santoku.env")

test("interpreter", function ()

end)

test("env", function ()

  local ok, _ = pcall(env.var, "ASDF123")
  assert(false == ok)

  local ok, val = pcall(env.var, "ASDF123", "hello")
  assert(true == ok)
  assert("hello" == val)

  local ok, val = pcall(env.var, "ASDF123", nil)
  assert(true == ok)
  assert(nil == val)

end)

test("path accessors", function ()
  assert(env.path() == package.path)
  assert(env.cpath() == package.cpath)
end)

if env.searchpath("santoku.env", package.path) then
  test("searchpath defaults to package.path", function ()
    local explicit = env.searchpath("santoku.env", package.path)
    assert(explicit ~= nil)
    assert(env.searchpath("santoku.env") == explicit)
  end)
end

test("with_paths swaps and restores", function ()
  local old_path = package.path
  local old_cpath = package.cpath
  local a, b = env.with_paths("./?.x", "./?.y", function (v)
    assert(package.path == "./?.x")
    assert(package.cpath == "./?.y")
    return v, "second"
  end, "first")
  assert(a == "first" and b == "second")
  assert(package.path == old_path)
  assert(package.cpath == old_cpath)
  local ok = pcall(env.with_paths, "./?.x", nil, function ()
    error("boom")
  end)
  assert(ok == false)
  assert(package.path == old_path)
  assert(package.cpath == old_cpath)
end)
