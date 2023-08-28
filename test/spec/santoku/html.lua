local test = require("santoku.test")
local html = require("santoku.html")
local assert = require("luassert")

test("html", function ()

  local str

  str = html({ "h1", "One" })

  assert.equals(str, [[<h1>One</h1>]])

  str = html({ "input", type = "text" })

  assert.equals(str, [[<input type="text"/>]])

  str = html(
    { "div", class = "container",
      { "div", class = "item",
        { "h1", "One" } },
      { "div", class = "item",
        { "h1", "Two" } } })

  assert.equals(str, [[<div class="container"><div class="item"><h1>One</h1></div><div class="item"><h1>Two</h1></div></div>]])

end)
