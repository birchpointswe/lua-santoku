local assert = require("luassert")
local test = require("santoku.test")

local template = require("santoku.template")
local vec = require("santoku.vector")
local fs = require("santoku.fs")

test("template", function ()

  test("should compile a template string", function ()
    local ok, tpl = template("<title><%render% return title %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  test("should allow custom delimiters", function ()
    local ok, tpl = template("<title>{{ return title }}</title>", { open = "{{", close = "}}" })
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  test("should handle multiple replacements", function ()
    local ok, tpl = template("<title><% return title %> <% return title %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! Hello, World!</title>")
  end)

  test("should handle multiple replacements", function ()
    local ok, tpl = template("<%compile% a = check(template:compilefile('test/res/template/title.html')) %><title><% return a:render() %></title>") -- luacheck: ignore
    assert(ok, tpl)
    assert.same(tpl.deps, vec("test/res/template/title.html"))
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  test("should support sharing fenv to child templates", function ()
    local ok, tpl = template("<% title = 'Hello, World!' %><title><% return check(template:compilefile('test/res/template/title.html')):render() %></title>") -- luacheck: ignore
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  test("should handle whitespace between blocks", function ()
    local ok, tpl = template("<title><% return check(template:compilefile('test/res/template/title.html')):render() %> <% return check(template:compilefile('test/res/template/name.html')):render() %></title>") -- luacheck: ignore
    assert(ok, tpl)
    local ok, str = tpl:render({
      title = "Hello, World!",
      name = "123"
    })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! 123</title>")
  end)

  test("should support multiple nesting levels ", function ()
    local ok, tpl = template("<title><% return check(template:compilefile('test/res/template/titles.html')):render() %></title>") -- luacheck: ignore
    assert(ok, tpl)
    local ok, str = tpl:render({
      title = "Hello, World!",
      name = "123"
    })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! 123</title>")
  end)

  test("should support multiple templates", function ()
    local ok, tpl = template("<%compile% a, b = check(template:compilefile('test/res/template/title.html')), check(template:compilefile('test/res/template/titles.html')) %><title><% return a:render() %> <% return b:render() %></title>") -- luacheck: ignore
    assert(ok, tpl)
    assert.same(tpl.deps, vec("test/res/template/title.html", "test/res/template/titles.html"))
    local ok, str = tpl:render({
      title = "Hello, World!",
      name = "123"
    })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! Hello, World! 123</title>")
  end)

  test("should support multiple templates (again)", function ()
    local ok, getconfig = fs.loadfile("test/res/template/config.lua")
    assert(ok, getconfig)
    local config = getconfig()
    local ok, data = fs.readfile("test/res/template/index.html")
    assert(ok, data)
    local ok, tpl = template(data, config)
    assert(ok, tpl)
    local ok, str = tpl()
    assert(ok, str)
  end)

  test("should handle trailing characters", function ()
    local ok, tpl = template([[
      <template
        data-api="/api/ping"
        data-method="get"
        <% return gen.pairs(redirects)
            :map(function (status, redirect)
              return string.format("data-handler-%d=\"redirect:%s\"", status, redirect)
            end)
            :concat("\n") %>>
      </template>
    ]])
    assert(ok, tpl)
    local ok, str = tpl:render({
      gen = require("santoku.gen"),
      string = string,
      redirects = { [403] = "/login" }
    })
    assert(ok, str)
    assert.same([[
      <template
        data-api="/api/ping"
        data-method="get"
        data-handler-403="redirect:/login">
      </template>
    ]], str) -- TODO: Should this ']]' be hanging?
  end)

  test("should allow multiple compile-time functions", function ()
    local ok, tpl = template([[
      <%compile% return title %>
      <%compile% return name %>
      <% return "!" %>
    ]], {
      env = {
        title = "Hello",
        name = "World"
      }
    })
    assert(ok, tpl)
    local ok, str = tpl:render()
    assert(ok, str)
    assert.same([[
      Hello
      World
      !
    ]], str)
  end)

  test("should support show/hide", function ()
    local ok, tpl = template([[
      One
      <% template:push(false) -- true, false %>
      Two
      <% template:pop():push(true) -- true, true %>
      Three
      <% template:push(false) -- true, true, false %>
      Four
      <% template:pop() -- true, true %>
      Five
      <% template:pop() -- true %>
      Six
      <% template:push(false) -- true, false %>
      Seven
      <% template:push(true) -- true, false, true %>
      Eight
      <% template:push(true) -- true, false, true, true %>
      Nine
      <% template:pop() -- true, false, true %>
      Ten
      <% template:pop() -- true, false %>
      Eleven
      <% template:pop() -- true %>
      Twelve
    ]])
    assert(ok, tpl)
    local ok, str = tpl:render()
    assert(ok, str)
    assert.same([[
      One
      Three
      Five
      Six
      Twelve
    ]], str)
  end)

  test("should prepend leading characters to new lines", function ()
    local ok, tpl = template([[
      start
      #  <% return "a\nb\nc" %>
      #  <% return "%%d\n%e\n%f" %>
    ]])
    assert(ok, tpl)
    local ok, str = tpl:render()
    assert(ok, str)
    assert.same([[
      start
      #  a
      #  b
      #  c
      #  %%d
      #  %e
      #  %f
    ]], str)
  end)

end)
