local test = require("santoku.test")
local assert = require("luassert")
local async = require("santoku.async")

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

    async.pipe(fetch, status, function (ok, data)
      assert.equals(true, ok)
      assert.equals(200, data)
    end)(in_url)

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

    async.pipe(fetch, status, function (ok, data)
      assert.equals(false, ok)
      assert.equals(in_err, data)
    end)(in_url)

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

    async.pipe(fetch, status, function (ok, data)
      assert.equals(false, ok)
      assert.equals(in_err, data)
    end)(in_url)

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

    async.pipe(fetch, status, function (ok, data)
      assert.equals(true, ok)
      assert.equals(200, data)
    end)(in_url)

  end)

end)
