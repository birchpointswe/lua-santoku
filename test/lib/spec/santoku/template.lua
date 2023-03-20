local template = require("santoku.template")
local fs = require("santoku.fs")

describe("template", function ()

  it("should compile a template string", function ()
    local ok, tpl = template("<title><% return title %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  it("should allow custom delimiters", function ()
    local ok, tpl = template("<title>{{ return title }}</title>", { open = "{{", close = "}}" })
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  it("should handle multiple replacements", function ()
    local ok, tpl = template("<title><% return title %> <% insert(title) %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! Hello, World!</title>")
  end)

  it("should handle multiple replacements", function ()
    local ok, tpl = template("<title><% extend(\"test/lib/spec/santoku/template/title.html\") %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  it("should support sharing fenv to child templates", function ()
    local ok, tpl = template("<% title = \"Hello, World!\" %><title><% extend(\"test/lib/spec/santoku/template/title.html\") %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  it("should handle whitespace between blocks", function ()
    local ok, tpl = template("<title><% extend('test/lib/spec/santoku/template/title.html') %> <% extend('test/lib/spec/santoku/template/name.html') %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({
      title = "Hello, World!",
      name = "123"
    })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! 123</title>")
  end)

  it("should support multiple nesting levels ", function ()
    local ok, tpl = template("<title><% extend(\"test/lib/spec/santoku/template/titles.html\") %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({
      title = "Hello, World!",
      name = "123"
    })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! 123</title>")
  end)

  it("should support multiple templates", function ()
    local ok, tpl = template("<title><% extend(\"test/lib/spec/santoku/template/title.html\") %> <% extend(\"test/lib/spec/santoku/template/titles.html\") %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({
      title = "Hello, World!",
      name = "123"
    })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! Hello, World! 123</title>")
  end)

  it("should support multiple templates (again)", function ()
    local ok, getconfig = fs.loadfile("test/lib/spec/santoku/template/config.lua")
    assert(ok, getconfig)
    local config = getconfig()
    local ok, data = fs.readfile("test/lib/spec/santoku/template/index.html")
    assert(ok, data)
    local ok, tpl = template(data, config)
    assert(ok, tpl)
    local ok, str = tpl()
    assert(ok, str)
  end)

end)
