local test = require("santoku.test")
local html = require("santoku.html")
local assert = require("luassert")

test("html", function ()

  local text = "this is a test of <span class=\"thing\" id='\"hi\"' failme=\"test: \\\"blah\\\": it's bound to fail\">something</span>" -- luacheck: ignore

  local tokens = html.parse(text):vec()

  assert.same({
    { start = 1,   position = 19,   text = "this is a test of " },
    { start = 19,  position = 25,   open = "span" },
    { start = 25,  position = 39,   attribute = { name = "class", value = "thing" } },
    { start = 39,  position = 49,   attribute = { name = "id", value = "\"hi\"" } },
    { start = 49,  position = 92,   attribute = { name = "failme", value = "test: \"blah\": it's bound to fail" } },
    { start = 93,  position = 102,  text = "something" },
    { start = 102, position = 109,  close = "span" },
    n = 7
  }, tokens)

end)
