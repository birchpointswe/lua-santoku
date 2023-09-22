local test = require("santoku.test")
local assert = require("luassert")
local async = require("santoku.async")

test("async", function ()

  test("pipe true", function ()

    local in_url = "https://santoku.rocks"
    local in_resp = { url = url, status = 200 }

    local function fetch (url, callback)
      assert.equals(in_url, url)
      return callback(true, in_resp)
    end

    local function status (resp, callback)
      assert.equals(in_resp, resp)
      return callback(true, resp.status)
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

    local function fetch (url, callback)
      assert.equals(in_url, url)
      return callback(false, in_err)
    end

    local function status (resp, callback)
      return callback(true, resp.status)
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

    local function fetch (url, callback)
      assert.equals(in_url, url)
      return callback(true, in_resp)
    end

    local function status (resp, callback)
      assert.equals(in_resp, resp)
      return callback(false, in_err)
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

    local function fetch (url, callback)
      assert.equals(in_url, url)
      return callback(true, in_resp, in_extra)
    end

    local function status (resp, extra, callback)
      assert.equals(in_resp, resp)
      assert.equals(in_extra, extra)
      return callback(true, resp.status)
    end

    async.pipe(fetch, status, function (ok, data)
      assert.equals(true, ok)
      assert.equals(200, data)
    end)(in_url)

  end)

end)
