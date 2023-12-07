local test = require("santoku.test")
local html = require("santoku.html")
local assert = require("luassert")

test("html", function ()

  local text = "this is a test of <span class=\"thing\" id='hi' failme='test: \"blah\": it\\'s bound to fail'>something</span>"

  local tokens = html.parse(text):vec()

  assert.same({
    { start = 1, position = 19, text = "this is a test of " },
  }, tokens)

end)
