local test = require("santoku.test")

local tbl = require("santoku.table")
local teq = tbl.equals

local validate = require("santoku.validate")
local isfalse = validate.isfalse
local isstring = validate.isstring
local iseq = validate.isequal

local err = require("santoku.error")
local _error = error
local error = err.error
local assert = err.assert
local pcall = err.pcall
local xpcall = err.xpcall
local wrapnil = err.wrapnil
local wrapok = err.wrapok

test("pcall", function ()
  assert(teq({ false, 1, 2, 3 }, {
    pcall(function ()
      error(1, 2, 3)
    end)
  }))
  assert(teq({ true, "hi" }, {
    pcall(function ()
      return "hi"
    end)
  }))
  local ok, msg = pcall(_error, "hi")
  assert(isfalse(ok))
  assert(isstring(msg))
  assert(iseq(msg, "hi"))
end)

test("xpcall", function ()
  assert(teq({ false, true, 1, 2, 3 }, {
    xpcall(function ()
      error(1, 2)
    end, function (...)
      assert(teq({ 1, 2 }, { ... }))
        return 1, 2, 3
    end)
  }))
  local c = 0
  assert(teq({ false, false, 1, 2, 3, 4 }, {
    xpcall(function ()
      error("hi")
    end, function (...)
      assert(teq({ "hi" }, { ... }))
      c = c + 1
      error(1, 2, 3, 4)
    end)
  }))
end)

test("xpcall returned values", function ()
  assert(teq({ false, true, 3, 4 }, {
    xpcall(function ()
      error(1, 2)
    end, function (...)
      assert(teq({ 1, 2 }, { ... }))
      return 3, 4
    end)
  }))
end)

test("wrapnil", function ()
  assert(teq({ false, "error", 1 }, {
    pcall(wrapnil(function ()
      return nil, "error", 1
    end))
  }))
  assert(teq({ true, "value", 1 }, {
    pcall(wrapnil(function ()
      return "value", 1
    end))
  }))
end)

test("wrapok", function ()
  assert(teq({ false, "error", 1 }, {
    pcall(wrapok(function ()
      return false, "error", 1
    end))
  }))
  assert(teq({ true, "value", 1 }, {
    pcall(wrapok(function ()
      return true, "value", 1
    end))
  }))
end)

test("assert", function ()
  assert(teq({ false, "hello", 1, 2, 3 }, {
    pcall(assert, false, "hello", 1, 2, 3)
  }))
end)
