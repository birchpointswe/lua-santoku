local test = require("santoku.test")
local css = require("santoku.css")
local assert = require("luassert")

test("css", function ()

  -- TODO: test id and keyframes
  local c, i, k, render = css()

  local str, names = render(
    c.header / c.title % {
      font_size = "2rem"
    },
    c.main * c.content % {
      display = "flex"
    })

  assert.equals(str,
    ".1 > .2 { font-size: 2rem; } .3 .4 { display: flex; } ")

  assert.equals("1", names.header)
  assert.equals("2", names.title)
  assert.equals("3", names.main)
  assert.equals("4", names.content)

end)
