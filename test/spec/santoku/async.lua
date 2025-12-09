local test = require("santoku.test")
local async = require("santoku.async")

local err = require("santoku.error")
local assert = err.assert

local validate = require("santoku.validate")
local eq = validate.isequal
local isnil = validate.isnil

local tbl = require("santoku.table")
local teq = tbl.equals

local arr = require("santoku.array")
local push = arr.push

test("pipe true", function ()

  local in_url = "https://santoku.rocks"
  local in_resp = { url = in_url, status = 200 }

  local function fetch (done, url)
    assert(eq(in_url, url))
    return done(true, in_resp)
  end

  local function status (done, resp)
    assert(eq(in_resp, resp))
    return done(true, resp.status)
  end

  async.pipe(function (done)
    return fetch(done, in_url)
  end, status, function (ok, data)
    assert(eq(true, ok))
    assert(eq(200, data))
  end)

end)

test("pipe first false", function ()

  local in_url = "https://santoku.rocks"
  local in_err = "some error"

  local function fetch (done, url)
    assert(eq(in_url, url))
    return done(false, in_err)
  end

  local function status (done, resp)
    return done(true, resp.status)
  end

  async.pipe(function (done)
    return fetch(done, in_url)
  end, status, function (ok, data)
    assert(eq(false, ok))
    assert(eq(in_err, data))
  end)

end)

test("pipe last false", function ()

  local in_url = "https://santoku.rocks"
  local in_resp = { url = in_url, status = 200 }
  local in_err = "some error"

  local function fetch (done, url)
    assert(eq(in_url, url))
    return done(true, in_resp)
  end

  local function status (done, resp)
    assert(eq(in_resp, resp))
    return done(false, in_err)
  end

  async.pipe(function (done)
    return fetch(done, in_url)
  end, status, function (ok, data)
    assert(eq(false, ok))
    assert(eq(in_err, data))
  end)

end)

test("pipe true", function ()

  local in_url = "https://santoku.rocks"
  local in_resp = { url = in_url, status = 200 }
  local in_extra = "testing"

  local function fetch (done, url)
    assert(eq(in_url, url))
    return done(true, in_resp, in_extra)
  end

  local function status (done, resp, extra)
    assert(eq(in_resp, resp))
    assert(eq(in_extra, extra))
    return done(true, resp.status)
  end

  async.pipe(function (done)
    return fetch(done, in_url)
  end, status, function (ok, data)
    assert(eq(true, ok))
    assert(eq(200, data))
  end)

end)

test("iter", function ()

  local idx = 0
  local results = {}

  async.iter(function (yield, done)
    idx = idx + 1
    if idx > 5 then
      return done(true)
    else
      return yield(idx)
    end
  end, function (done, data)
    assert(eq(data, idx))
    push(results, data)
    return done(true)
  end, function (ok, err)
    assert(eq(ok, true))
    assert(isnil(err))
  end)

  assert(teq({ 1, 2, 3, 4, 5 }, results))

end)

test("loop", function ()

  local idx = 0
  async.loop(function (loop, stop, ...)
    idx = idx + 1
    if idx > 5 then
      return stop(true, ...)
    else
      return loop(idx, ...)
    end
  end, function (ok, ...)
    assert(eq(true, ok))
    assert(teq({ 5, 4, 3, 2, 1 }, { ... }))
  end)

end)

test("events emit", function ()
  local x = 0
  local y = 0
  local events = async.events()
  events.on("e", function (...)
    assert(teq({ select("#", ...) }, { 1 }))
    assert(teq({ ... }, { 5 }))
    x = x + (...)
  end)
  events.emit("e", 5)
  events.emit("e", 5)
  assert(teq({ x }, { 10 }))
  events.on("e", function (k, n)
    return k(n + 1)
  end, true)
  events.on("e", function (...)
    assert(teq({ select("#", ...) }, { 1 }))
    assert(teq({ ... }, { 6 }))
    y = y + ...
  end)
  events.emit("e", 5)
  assert(teq({ x }, { 15 }))
  assert(teq({ y }, { 6 }))
end)

test("events process", function ()
  local x = 0
  local events = async.events()
  events.on("e", function (...)
    assert(teq({ select("#", ...) }, { 1 }))
    assert(teq({ ... }, { 5 }))
    x = x + (...)
  end)
  events.process("e", function (k, ...)
    assert(teq({ select("#", ...) }, { 1 }))
    assert(teq({ ... }, { 5 }))
    return k((...) + 1)
  end, function (...)
    assert(teq({ x }, { 5 }))
    assert(teq({ ... }, { 6 }))
  end, 5)
end)

test("consume", function ()
  local data = { 1, 2, 3, 4, 5 }
  local idx = 0
  local gen = function ()
    idx = idx + 1
    return data[idx]
  end
  local results = {}
  async.consume(gen)(function (done, v)
    push(results, v)
    return done(true)
  end, function (ok)
    assert(eq(true, ok))
  end)
  assert(teq({ 1, 2, 3, 4, 5 }, results))
end)

test("ipairs", function ()
  local t = { "a", "b", "c" }
  local results = {}
  async.ipairs(function (helper, k, i, v, ud)
    push(results, { i, v })
    return helper(k, i, ud + 1)
  end, t, 0)
  assert(teq({ { 1, "a" }, { 2, "b" }, { 3, "c" } }, results))
end)

test("id", function ()
  local called = false
  async.id(function (...)
    called = true
    assert(teq({ 1, 2, 3 }, { ... }))
  end, 1, 2, 3)
  assert(called)
end)

test("all success", function ()
  local order = {}
  async.all({
    function (done) push(order, 1); done(true, "a") end,
    function (done) push(order, 2); done(true, "b") end,
    function (done) push(order, 3); done(true, "c") end,
  }, function (ok, results)
    assert(eq(true, ok))
    assert(teq({ "a", "b", "c" }, results))
  end)
  assert(teq({ 1, 2, 3 }, order))
end)

test("all failure", function ()
  local called_third = false
  async.all({
    function (done) done(true, "a") end,
    function (done) done(false, "error") end,
    function (done) called_third = true; done(true, "c") end,
  }, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end)
  assert(called_third)
end)

test("all empty", function ()
  async.all({}, function (ok, results)
    assert(eq(true, ok))
    assert(teq({}, results))
  end)
end)

test("race success", function ()
  local completed = false
  async.race({
    function (done) done(true, "first") end,
    function (done) if not completed then done(true, "second") end end,
  }, function (ok, result)
    completed = true
    assert(eq(true, ok))
    assert(eq("first", result))
  end)
end)

test("race failure", function ()
  async.race({
    function (done) done(false, "error") end,
    function (done) done(true, "second") end,
  }, function (ok, result)
    assert(eq(false, ok))
    assert(eq("error", result))
  end)
end)

test("race empty", function ()
  async.race({}, function (ok)
    assert(eq(true, ok))
  end)
end)

test("series success", function ()
  local order = {}
  async.series({
    function (done) push(order, 1); done(true, "a") end,
    function (done, v) push(order, 2); assert(eq("a", v)); done(true, "b") end,
    function (done, v) push(order, 3); assert(eq("b", v)); done(true, "c") end,
  }, function (ok, result)
    assert(eq(true, ok))
    assert(eq("c", result))
  end)
  assert(teq({ 1, 2, 3 }, order))
end)

test("series failure", function ()
  local called_third = false
  async.series({
    function (done) done(true, "a") end,
    function (done) done(false, "error") end,
    function (done) called_third = true; done(true, "c") end,
  }, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end)
  assert(not called_third)
end)

test("series empty", function ()
  async.series({}, function (ok)
    assert(eq(true, ok))
  end)
end)

test("series with initial args", function ()
  async.series({
    function (done, x) done(true, x * 2) end,
    function (done, x) done(true, x + 1) end,
  }, function (ok, result)
    assert(eq(true, ok))
    assert(eq(11, result))
  end, 5)
end)

test("map success", function ()
  async.map({ 1, 2, 3 }, function (done, v, i)
    done(true, v * 10 + i)
  end, function (ok, results)
    assert(eq(true, ok))
    assert(teq({ 11, 22, 33 }, results))
  end)
end)

test("map failure", function ()
  local processed = {}
  async.map({ 1, 2, 3 }, function (done, v)
    push(processed, v)
    if v == 2 then
      done(false, "error at 2")
    else
      done(true, v * 10)
    end
  end, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error at 2", err))
  end)
  assert(teq({ 1, 2 }, processed))
end)

test("map empty", function ()
  async.map({}, function (done, v)
    done(true, v)
  end, function (ok, results)
    assert(eq(true, ok))
    assert(teq({}, results))
  end)
end)

test("filter success", function ()
  async.filter({ 1, 2, 3, 4, 5 }, function (done, v)
    done(true, v % 2 == 0)
  end, function (ok, results)
    assert(eq(true, ok))
    assert(teq({ 2, 4 }, results))
  end)
end)

test("filter failure", function ()
  async.filter({ 1, 2, 3 }, function (done, v)
    if v == 2 then
      done(false, "error")
    else
      done(true, true)
    end
  end, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end)
end)

test("filter empty", function ()
  async.filter({}, function (done)
    done(true, true)
  end, function (ok, results)
    assert(eq(true, ok))
    assert(teq({}, results))
  end)
end)

test("reduce success", function ()
  async.reduce({ 1, 2, 3, 4 }, function (done, acc, v)
    done(true, acc + v)
  end, 0, function (ok, result)
    assert(eq(true, ok))
    assert(eq(10, result))
  end)
end)

test("reduce failure", function ()
  async.reduce({ 1, 2, 3 }, function (done, acc, v)
    if v == 2 then
      done(false, "error")
    else
      done(true, acc + v)
    end
  end, 0, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end)
end)

test("reduce empty", function ()
  async.reduce({}, function (done, acc, v)
    done(true, acc + v)
  end, 42, function (ok, result)
    assert(eq(true, ok))
    assert(eq(42, result))
  end)
end)

test("reduce with index", function ()
  async.reduce({ "a", "b", "c" }, function (done, acc, v, i)
    done(true, acc .. v .. i)
  end, "", function (ok, result)
    assert(eq(true, ok))
    assert(eq("a1b2c3", result))
  end)
end)
