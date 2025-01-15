local test = require("santoku.test")
local async = require("santoku.async")

local it = require("santoku.iter")

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

test("each", function ()

  local g = it.ivals({ 1, 2, 3 })

  local t = 0
  local final = false

  async.each(g, function (done)
    t = t + 1
    done(true)
  end, function (ok, err)
    final = true
    assert(eq(3, t))
    assert(eq(true, ok))
    assert(isnil(err))
  end)

  assert(eq(true, final))

end)

test("each abort on fail", function ()
  local g = it.ivals({ 1, 2, 3, 4 })
  local cnt = 0
  async.each(g, function (done, a)
    cnt = cnt + a
    if cnt > 3 then
      done(false, "hi")
    else
      done(true)
    end
  end, function (ok, err)
    assert(ok == false and err == "hi")
    assert(cnt == 6)
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
