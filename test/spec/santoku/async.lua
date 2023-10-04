local test = require("santoku.test")
local assert = require("luassert")
local async = require("santoku.async")
local gen = require("santoku.gen")
local vec = require("santoku.vector")

test("async", function ()

  test("pipe true", function ()

    local in_url = "https://santoku.rocks"
    local in_resp = { url = url, status = 200 }

    local function fetch (done, url)
      assert.equals(in_url, url)
      return done(true, in_resp)
    end

    local function status (done, resp)
      assert.equals(in_resp, resp)
      return done(true, resp.status)
    end

    async.pipe(function (done)
      return fetch(done, in_url)
    end, status, function (ok, data)
      assert.equals(true, ok)
      assert.equals(200, data)
    end)

  end)

  test("pipe first false", function ()

    local in_url = "https://santoku.rocks"
    local in_resp = { url = url, status = 200 }
    local in_err = "some error"

    local function fetch (done, url)
      assert.equals(in_url, url)
      return done(false, in_err)
    end

    local function status (done, resp)
      return done(true, resp.status)
    end

    async.pipe(function (done)
      return fetch(done, in_url)
    end, status, function (ok, data)
      assert.equals(false, ok)
      assert.equals(in_err, data)
    end)

  end)

  test("pipe last false", function ()

    local in_url = "https://santoku.rocks"
    local in_resp = { url = url, status = 200 }
    local in_err = "some error"

    local function fetch (done, url)
      assert.equals(in_url, url)
      return done(true, in_resp)
    end

    local function status (done, resp)
      assert.equals(in_resp, resp)
      return done(false, in_err)
    end

    async.pipe(function (done)
      return fetch(done, in_url)
    end, status, function (ok, data)
      assert.equals(false, ok)
      assert.equals(in_err, data)
    end)

  end)

  test("pipe true", function ()

    local in_url = "https://santoku.rocks"
    local in_resp = { url = url, status = 200 }
    local in_extra = "testing"

    local function fetch (done, url)
      assert.equals(in_url, url)
      return done(true, in_resp, in_extra)
    end

    local function status (done, resp, extra)
      assert.equals(in_resp, resp)
      assert.equals(in_extra, extra)
      return done(true, resp.status)
    end

    async.pipe(function (done)
      return fetch(done, in_url)
    end, status, function (ok, data)
      assert.equals(true, ok)
      assert.equals(200, data)
    end)

  end)

  test("each", function ()

    local g = gen.pack(1, 2, 3):co()

    local t = 0
    local final = false

    async.each(g, function (done, n)
      t = t + 1
      done(true)
    end, function (ok, err)
      final = true
      assert.equals(3, t)
      assert.equals(true, ok)
      assert.is_nil(err)
    end)

    assert.equals(true, final)

  end)

  test("iter", function ()

    local idx = 0
    local results = vec()

    async.iter(function (yield, done)
      idx = idx + 1
      if idx > 5 then
        return done(true)
      else
        return yield(idx)
      end
    end, function (done, data)
      assert.equals(data, idx)
      results:append(data)
      return done(true)
    end, function (ok, err)
      assert.equals(ok, true)
      assert.is_nil(err)
    end)

    assert.same({ 1, 2, 3, 4, 5, n = 5 }, results)

  end)

end)
