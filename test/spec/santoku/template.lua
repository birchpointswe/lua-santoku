local tpl = require("santoku.template")

describe("template", function ()

  it("should compile a template string", function ()
    local ok, tpl = tpl("<title><% return title %></title>")
    assert(ok, tpl)
    local str = tpl:render({ title = "Hello, World!" })
    assert.same(str, "<title>Hello, World!</title>")
  end)

  it("should allow custom delimiters", function ()
    local ok, tpl = tpl("<title>{{ return title }}</title>", { open = "{{", close = "}}" })
    assert(ok, tpl)
    local str = tpl:render({ title = "Hello, World!" })
    assert.same(str, "<title>Hello, World!</title>")
  end)

  it("should transparently handle expressions", function ()
    local ok, tpl = tpl("<title><% title %></title>")
    assert(ok, tpl)
    local str = tpl:render({ title = "Hello, World!" })
    assert.same(str, "<title>Hello, World!</title>")
  end)

end)
