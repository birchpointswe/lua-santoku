-- Borrowed from:
-- https://raw.githubusercontent.com/saucisson/lua-coronest/master/src/coroutine/make.lua
--
-- TODO: Add a way to inject this factory
-- globally, so that whenever one of the
-- coroutine-creating functions (wrap, create)
-- are called, we implicitly create an instance
-- of this module. This should work inside
-- third-pary libraries
--
-- From mailing list:
--
-- You could temporarily replace the Lua
-- searcher in `package.searchers[ 2 ]` (or
-- insert a new one in `package.searchers[ 1 ]`)
-- to load certain libraries with a custom
-- environment that has the coroutines library
-- replaced and an `__index`/`__newindex` to the
-- real global environment.

local select = select
local create = coroutine.create
local isyieldable = coroutine.isyieldable -- luacheck: ignore
local resume = coroutine.resume
local running = coroutine.running
local status = coroutine.status
local wrap = coroutine.wrap
local yield = coroutine.yield

return {

  make = function (tag)

    local coroutine = {
      isyieldable = isyieldable,
      running = running,
      status = status,
    }

    tag = tag or {}

    local function for_wrap (co, ...)
      if tag == ... then
        return select(2, ...)
      else
        return for_wrap(co, co(yield(...)))
      end
    end

    local function for_resume (co, st, ...)
      if not st then
        return st, ...
      elseif tag == ... then
        return st, select(2, ...)
      else
        return for_resume(co, resume(co, yield(...)))
      end
    end

    function coroutine.create (f)
      return create(function (...)
        return tag, f(...)
      end)
    end

    function coroutine.resume (co, ...)
      return for_resume(co, resume(co, ...))
    end

    function coroutine.wrap (f)
      local co = wrap(function (...)
        return tag, f(...)
      end)
      return function (...)
        return for_wrap(co, co(...))
      end
    end

    function coroutine.yield (...)
      return yield (tag, ...)
    end

    return coroutine

  end

}
