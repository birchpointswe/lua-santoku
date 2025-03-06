local varg = require("santoku.varg")
local arr = require("santoku.array")
local fun = require("santoku.functional")
local tup = varg.tup

local M = {}

M._pipe = function (n, fns, ok, ...)
  if not ok or n == #fns then
    return fns[#fns](ok, ...)
  else
    return fns[n](function (...)
      return M._pipe(n + 1, fns, ...)
    end, ...)
  end
end

-- TODO: This should be generalizable. Some kind
-- of tup.reducek or tup.cont that reduces over
-- a list of arguments and allows for early
-- exit. tup.reduce_until? Something in iter?
M.pipe = function (...)
  local fns = { ... }
  return M._pipe(1, fns, true)
end

M._each = function (g, it, done)
  return tup(function (...)
    if ... == nil then
      return done(true)
    else
      return it(function (ok, ...)
        if not ok then
          return done(ok, ...)
        else
          return M._each(g, it, done)
        end
      end, ...)
    end
  end, g())
end

M.each = function (g, it, done)
  return M._each(g, it, done)
end

M._iter = function (y, it, done)
  return y(function (...)
    return it(function (ok, ...)
      if not ok then
        return done(ok, ...)
      else
        -- NOTE: Throwing away values returned
        -- from iteration function
        return M._iter(y, it, done)
      end
    end, ...)
  end, done)
end

M.iter = function (y, it, done)
  return M._iter(y, it, done)
end

M._loop = function (loop0, final, ...)
  return loop0(function (...)
    return M._loop(loop0, final, ...)
  end, function (...)
    return final(...)
  end, ...)
end

M.loop = function (loop0, final)
  return M._loop(loop0, final)
end

local run_process
run_process = function (hs, each, done, asy, i, ...)
  local h = hs and hs[i]
  if not h then
    return done(...)
  elseif not asy[h] then
    -- Note: intentionally not passing results to other
    -- handlers when not async
    h(...)
    return each(function (...)
      return run_process(hs, each, done, asy, i + 1, ...)
    end, ...)
  else
    return h(function (...) --
      return each(function (...)
        return run_process(hs, each, done, asy, i + 1, ...)
      end, ...)
    end, ...)
  end
end

M.id = function (k, ...)
  return k(...)
end

local _ipairs
_ipairs = function (k, t, ud)
  local helper
  helper = function (fn, i, ud)
    i = i + 1
    local v = t[i]
    if v == nil then
      return ud
    else
      return fn(helper, k, i, v, ud)
    end
  end
  return helper(k, 0, ud)
end

M.ipairs = _ipairs

local ALL_EVENTS = {}

M.events = function ()
  local idx = {}
  local hs = {}
  local asy = {}
  return {

    handlers = hs,
    index = idx,
    async = asy,

    -- TODO: Allow caller to pass an "order" argument, which is used to sort
    -- handlers. Handlers are sorted such that those with lower "orders" are
    -- called first, and those with the same order are called in the order in
    -- which they were registered.
    on = function (ev, handler, async)
      ev = ev == nil and ALL_EVENTS or ev
      if ev and handler then
        local hs0 = hs[ev] or {}
        hs[ev] = hs0
        hs0[#hs0 + 1] = handler
        idx[handler] = #hs0
        asy[handler] = async
      end
    end,

    off = function (ev, handler)
      ev = ev == nil and ALL_EVENTS or ev
      if ev and handler then
        local hs0 = hs[ev]
        if not hs0 then
          return
        end
        local i = idx[handler]
        if not i then
          return
        end
        arr.remove(hs0, i, i)
        idx[handler] = nil
        asy[handler] = nil
      end
    end,

    emit = function (ev, ...)
      local hs0 = ev and hs[ev]
      local hs1 = hs[ALL_EVENTS]
      return run_process(hs0, M.id, function (...)
        return run_process(hs1, M.id, fun.noop, asy, 1, ev, ...)
      end, asy, 1, ...)
    end,

    process = function (ev, each, done, ...)
      local hs0 = ev and hs[ev] or {}
      each = each or M.id
      done = done or fun.noop
      return run_process(hs0, each, done, asy, 1, ...)
    end

  }
end

return M
