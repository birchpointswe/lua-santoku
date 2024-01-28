local test = require("santoku.test")

local inherit = require("santoku.inherit")
local pushindex = inherit.pushindex
local popindex = inherit.popindex
local getindex = inherit.getindex

test("pushindex", function ()

  test("should add an index to a table", function ()

    local t = {}
    local i = { a = 1 }
    pushindex(t, i)
    assert(getindex(t) == i)
    assert(getindex(i) == nil)

  end)

  test("should preserve existing indexes", function ()

    local t = {}
    local i1 = { a = 1 }
    local i2 = { a = 2 }
    local i

    pushindex(t, i1)

    i = getindex(t)
    assert(i == i1)
    i = getindex(i1)
    assert(i == nil)

    pushindex(t, i2)

    i = getindex(t)
    assert(i == i2)

    i = getindex(i2)
    assert(i == i1)

    i = getindex(i1)
    assert(i == nil)

    i = popindex(t)
    assert(i == i2)

    i = getindex(i2)
    assert(i == i1)

    i = getindex(t)
    assert(i == i1)

    i = popindex(t)
    assert(i == i1)

  end)

end)

test("popindex", function ()

  test("should pop a single index", function ()

    local t = {}
    local i = { a = 1 }
    local i0

    pushindex(t, i)

    i0 = getindex(t)
    assert(i == i0)

    i0 = popindex(t)
    assert(i == i0)

    i0 = getindex(t)
    assert(i0 == nil)

  end)

end)
