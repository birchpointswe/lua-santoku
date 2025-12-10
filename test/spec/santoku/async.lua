local test = require("santoku.test")
local async = require("santoku.async")

local err = require("santoku.error")
local assert = err.assert

local validate = require("santoku.validate")
local eq = validate.isequal

local tbl = require("santoku.table")
local teq = tbl.equals

local arr = require("santoku.array")
local push = arr.push

test("ieach with ipairs", function ()
  local results = {}
  async.ieach(function (done, i, v)
    push(results, { i, v })
    return done(true)
  end, function (ok)
    assert(eq(true, ok))
  end, ipairs({ "a", "b", "c" }))
  assert(teq({ { 1, "a" }, { 2, "b" }, { 3, "c" } }, results))
end)

test("ieach with pairs", function ()
  local results = {}
  async.ieach(function (done, k, v)
    results[k] = v
    return done(true)
  end, function (ok)
    assert(eq(true, ok))
  end, pairs({ x = 1, y = 2 }))
  assert(teq({ x = 1, y = 2 }, results))
end)

test("ieach failure", function ()
  local results = {}
  async.ieach(function (done, _, v)
    push(results, v)
    if v == "b" then
      return done(false, "stopped")
    end
    return done(true)
  end, function (ok, err)
    assert(eq(false, ok))
    assert(eq("stopped", err))
  end, ipairs({ "a", "b", "c" }))
  assert(teq({ "a", "b" }, results))
end)

test("imap", function ()
  async.imap(function (done, i, v)
    done(true, v .. i)
  end, function (ok, results)
    assert(eq(true, ok))
    assert(teq({ "a1", "b2", "c3" }, results))
  end, ipairs({ "a", "b", "c" }))
end)

test("imap failure", function ()
  async.imap(function (done, _, v)
    if v == "b" then
      done(false, "error")
    else
      done(true, v)
    end
  end, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end, ipairs({ "a", "b", "c" }))
end)

test("ifilter", function ()
  async.ifilter(function (done, i)
    done(true, i % 2 == 0)
  end, function (ok, results)
    assert(eq(true, ok))
    assert(teq({ 2, 4 }, results))
  end, ipairs({ 1, 2, 3, 4, 5 }))
end)

test("ifilter failure", function ()
  async.ifilter(function (done, i)
    if i == 3 then
      done(false, "error")
    else
      done(true, true)
    end
  end, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end, ipairs({ 1, 2, 3, 4 }))
end)

test("ifiltermap", function ()
  async.ifiltermap(function (done, i, v)
    if i % 2 == 0 then
      done(true, v .. "!")
    else
      done(true, nil)
    end
  end, function (ok, results)
    assert(eq(true, ok))
    assert(teq({ "b!", "d!" }, results))
  end, ipairs({ "a", "b", "c", "d" }))
end)

test("ifiltermap failure", function ()
  async.ifiltermap(function (done, i)
    if i == 2 then
      done(false, "error")
    else
      done(true, i)
    end
  end, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end, ipairs({ 1, 2, 3 }))
end)

test("ireduce", function ()
  async.ireduce(function (done, acc, _, v)
    done(true, acc + v)
  end, 0, function (ok, result)
    assert(eq(true, ok))
    assert(eq(10, result))
  end, ipairs({ 1, 2, 3, 4 }))
end)

test("ireduce failure", function ()
  async.ireduce(function (done, acc, i)
    if i == 3 then
      done(false, "error")
    else
      done(true, acc + i)
    end
  end, 0, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end, ipairs({ 1, 2, 3, 4 }))
end)

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

test("pipe with array", function ()
  async.pipe({
    function (done) done(true, 1) end,
    function (done, v) done(true, v + 1) end,
    function (ok, v)
      assert(eq(true, ok))
      assert(eq(2, v))
    end
  })
end)

test("pipe first false", function ()
  local in_url = "https://santoku.rocks"
  local in_err = "some error"

  local function fetch (done)
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

test("race success", function ()
  local completed = false
  async.race(
    function (done) done(true, "first") end,
    function (done) if not completed then done(true, "second") end end,
    function (ok, result)
      completed = true
      assert(eq(true, ok))
      assert(eq("first", result))
    end)
end)

test("race with array", function ()
  async.race({
    function (done) done(true, "winner") end,
    function (done) done(true, "loser") end,
  }, function (ok, result)
    assert(eq(true, ok))
    assert(eq("winner", result))
  end)
end)

test("race failure", function ()
  async.race(
    function (done) done(false, "error") end,
    function (done) done(true, "second") end,
    function (ok, result)
      assert(eq(false, ok))
      assert(eq("error", result))
    end)
end)

test("race empty", function ()
  async.race(function (ok)
    assert(eq(true, ok))
  end)
end)

test("events emit", function ()
  local x = 0
  local events = async.events()
  events.on("e", function (...)
    assert(teq({ select("#", ...) }, { 1 }))
    assert(teq({ ... }, { 5 }))
    x = x + (...)
  end)
  events.emit("e", 5)
  events.emit("e", 5)
  assert(teq({ x }, { 10 }))
end)

test("events async handler", function ()
  local x = 0
  local y = 0
  local events = async.events()
  events.on("e", function (n)
    x = x + n
  end)
  events.on("e", function (k, n)
    return k(n + 1)
  end, true)
  events.on("e", function (n)
    y = y + n
  end)
  events.emit("e", 5)
  assert(eq(5, x))
  assert(eq(6, y))
end)

test("events off", function ()
  local called = false
  local events = async.events()
  local handler = function () called = true end
  events.on("e", handler)
  events.off("e", handler)
  events.emit("e")
  assert(not called)
end)

test("each success", function ()
  local results = {}
  local t = { 1, 2, 3 }
  async.each(t, function (done, v, i)
    push(results, { i, v })
    done(true)
  end, function (ok)
    assert(eq(true, ok))
  end)
  assert(teq({ { 1, 1 }, { 2, 2 }, { 3, 3 } }, results))
end)

test("each failure", function ()
  local processed = {}
  async.each({ 1, 2, 3 }, function (done, v)
    push(processed, v)
    if v == 2 then
      done(false, "error")
    else
      done(true)
    end
  end, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end)
  assert(teq({ 1, 2 }, processed))
end)

test("each empty", function ()
  async.each({}, function (done)
    done(true)
  end, function (ok)
    assert(eq(true, ok))
  end)
end)

test("map success in-place", function ()
  local t = { 1, 2, 3 }
  async.map(t, function (done, v, i)
    done(true, v * 10 + i)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(result == t)
    assert(teq({ 11, 22, 33 }, t))
  end)
end)

test("map failure", function ()
  local processed = {}
  local t = { 1, 2, 3 }
  async.map(t, function (done, v)
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
  local t = {}
  async.map(t, function (done, v)
    done(true, v)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(result == t)
  end)
end)

test("filter success in-place", function ()
  local t = { 1, 2, 3, 4, 5 }
  async.filter(t, function (done, v)
    done(true, v % 2 == 0)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(result == t)
    assert(teq({ 2, 4 }, t))
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
  local t = {}
  async.filter(t, function (done)
    done(true, true)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(result == t)
  end)
end)

test("reduce success", function ()
  async.reduce({ 1, 2, 3, 4 }, function (done, acc, v)
    done(true, acc + v)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(eq(10, result))
  end, 0)
end)

test("reduce default init", function ()
  async.reduce({ 1, 2, 3 }, function (done, acc, v)
    done(true, acc + v)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(eq(6, result))
  end)
end)

test("reduce failure", function ()
  async.reduce({ 1, 2, 3 }, function (done, acc, v)
    if v == 2 then
      done(false, "error")
    else
      done(true, acc + v)
    end
  end, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end, 0)
end)

test("reduce empty", function ()
  async.reduce({}, function (done, acc, v)
    done(true, acc + v)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(eq(42, result))
  end, 42)
end)

test("reduce with index", function ()
  async.reduce({ "a", "b", "c" }, function (done, acc, v, i)
    done(true, acc .. v .. i)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(eq("a1b2c3", result))
  end, "")
end)

test("all success", function ()
  local order = {}
  local t = { 1, 2, 3 }
  async.all(t, function (done, v)
    push(order, v)
    done(true)
  end, function (ok)
    assert(eq(true, ok))
  end)
  assert(teq({ 1, 2, 3 }, order))
end)

test("all failure", function ()
  local t = { 1, 2, 3 }
  async.all(t, function (done, v)
    if v == 2 then
      done(false, "error")
    else
      done(true)
    end
  end, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end)
end)

test("all empty", function ()
  async.all({}, function (done)
    done(true)
  end, function (ok)
    assert(eq(true, ok))
  end)
end)

test("mapall success", function ()
  local t = { 1, 2, 3 }
  async.mapall(t, function (done, v, i)
    done(true, v * 10 + i)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(result == t)
    assert(teq({ 11, 22, 33 }, t))
  end)
end)

test("mapall failure", function ()
  local t = { 1, 2, 3 }
  async.mapall(t, function (done, v)
    if v == 2 then
      done(false, "error")
    else
      done(true, v * 10)
    end
  end, function (ok, err)
    assert(eq(false, ok))
    assert(eq("error", err))
  end)
end)

test("mapall empty", function ()
  local t = {}
  async.mapall(t, function (done, v)
    done(true, v)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(result == t)
  end)
end)

test("filterall success", function ()
  local t = { 1, 2, 3, 4, 5 }
  async.filterall(t, function (done, v)
    done(true, v % 2 == 0)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(result == t)
    assert(teq({ 2, 4 }, t))
  end)
end)

test("filterall failure", function ()
  local t = { 1, 2, 3 }
  async.filterall(t, function (done, v)
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

test("filterall empty", function ()
  local t = {}
  async.filterall(t, function (done)
    done(true, true)
  end, function (ok, result)
    assert(eq(true, ok))
    assert(result == t)
  end)
end)
