local arr = require("santoku.array")

local M = {}

local function normalize_fns (...)
  local first = ...
  if type(first) == "table" then
    return first
  else
    return { ... }
  end
end

local function _ieach (fn, done, iter_fn, state, var)
  local values = { iter_fn(state, var) }
  if values[1] == nil then
    return done(true)
  else
    return fn(function (ok, ...)
      if not ok then
        return done(ok, ...)
      else
        return _ieach(fn, done, iter_fn, state, values[1])
      end
    end, arr.spread(values))
  end
end

M.ieach = function (fn, done, iter_fn, state, var)
  return _ieach(fn, done, iter_fn, state, var)
end

local function _imap (fn, done, iter_fn, state, var, results)
  local values = { iter_fn(state, var) }
  if values[1] == nil then
    return done(true, results)
  else
    return fn(function (ok, v)
      if not ok then
        return done(ok, v)
      else
        results[#results + 1] = v
        return _imap(fn, done, iter_fn, state, values[1], results)
      end
    end, arr.spread(values))
  end
end

M.imap = function (fn, done, iter_fn, state, var)
  return _imap(fn, done, iter_fn, state, var, {})
end

local function _ifilter (fn, done, iter_fn, state, var, results)
  local values = { iter_fn(state, var) }
  if values[1] == nil then
    return done(true, results)
  else
    return fn(function (ok, keep)
      if not ok then
        return done(ok, keep)
      else
        if keep then
          results[#results + 1] = values[1]
        end
        return _ifilter(fn, done, iter_fn, state, values[1], results)
      end
    end, arr.spread(values))
  end
end

M.ifilter = function (fn, done, iter_fn, state, var)
  return _ifilter(fn, done, iter_fn, state, var, {})
end

local function _ifiltermap (fn, done, iter_fn, state, var, results)
  local values = { iter_fn(state, var) }
  if values[1] == nil then
    return done(true, results)
  else
    return fn(function (ok, v)
      if not ok then
        return done(ok, v)
      else
        if v ~= nil then
          results[#results + 1] = v
        end
        return _ifiltermap(fn, done, iter_fn, state, values[1], results)
      end
    end, arr.spread(values))
  end
end

M.ifiltermap = function (fn, done, iter_fn, state, var)
  return _ifiltermap(fn, done, iter_fn, state, var, {})
end

local function _ireduce (fn, done, iter_fn, state, var, acc)
  local values = { iter_fn(state, var) }
  if values[1] == nil then
    return done(true, acc)
  else
    return fn(function (ok, v)
      if not ok then
        return done(ok, v)
      else
        return _ireduce(fn, done, iter_fn, state, values[1], v)
      end
    end, acc, arr.spread(values))
  end
end

M.ireduce = function (fn, init, done, iter_fn, state, var)
  return _ireduce(fn, done, iter_fn, state, var, init)
end

local function _pipe (fns, n, ok, ...)
  if not ok or n == #fns then
    return fns[#fns](ok, ...)
  else
    return fns[n](function (...)
      return _pipe(fns, n + 1, ...)
    end, ...)
  end
end

M.pipe = function (...)
  return _pipe(normalize_fns(...), 1, true)
end

local function _loop (fn, done, ...)
  return fn(function (...)
    return _loop(fn, done, ...)
  end, done, ...)
end

M.loop = function (fn, done)
  return _loop(fn, done)
end

M.race = function (first, ...)
  local fns, done
  if type(first) == "table" then
    fns = first
    done = ...
  else
    fns = { first, ... }
    fns, done = arr.pop(fns)
  end
  local n = #fns
  if n == 0 then
    return done(true)
  end
  local finished = false
  for i = 1, n do
    fns[i](function (ok, ...)
      if finished then return end
      finished = true
      return done(ok, ...)
    end)
  end
end

local ALL_EVENTS = {}

local function run_events (hs, asy, i, ...)
  local h = hs and hs[i]
  if not h then
    return
  elseif not asy[h] then
    h(...)
    return run_events(hs, asy, i + 1, ...)
  else
    return h(function (...)
      return run_events(hs, asy, i + 1, ...)
    end, ...)
  end
end

M.events = function ()
  local idx = {}
  local hs = {}
  local asy = {}
  return {
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
      run_events(hs[ev], asy, 1, ...)
      return run_events(hs[ALL_EVENTS], asy, 1, ev, ...)
    end
  }
end

local function _each (t, fn, done, i)
  if i > #t then
    return done(true)
  end
  return fn(function (ok, ...)
    if not ok then
      return done(ok, ...)
    end
    return _each(t, fn, done, i + 1)
  end, t[i], i)
end

M.each = function (t, fn, done)
  return _each(t, fn, done, 1)
end

local function _map (t, fn, done, i)
  if i > #t then
    return done(true, t)
  end
  return fn(function (ok, v)
    if not ok then
      return done(ok, v)
    end
    t[i] = v
    return _map(t, fn, done, i + 1)
  end, t[i], i)
end

M.map = function (t, fn, done)
  return _map(t, fn, done, 1)
end

local function _filter (t, fn, done, i, j)
  if i > #t then
    for k = j, #t do
      t[k] = nil
    end
    return done(true, t)
  end
  return fn(function (ok, keep)
    if not ok then
      return done(ok, keep)
    end
    if keep then
      t[j] = t[i]
      return _filter(t, fn, done, i + 1, j + 1)
    else
      return _filter(t, fn, done, i + 1, j)
    end
  end, t[i], i)
end

M.filter = function (t, fn, done)
  return _filter(t, fn, done, 1, 1)
end

local function _reduce (t, fn, done, i, acc)
  if i > #t then
    return done(true, acc)
  end
  return fn(function (ok, v)
    if not ok then
      return done(ok, v)
    end
    return _reduce(t, fn, done, i + 1, v)
  end, acc, t[i], i)
end

M.reduce = function (t, fn, done, init)
  if init == nil then
    return _reduce(t, fn, done, 2, t[1])
  else
    return _reduce(t, fn, done, 1, init)
  end
end

M.all = function (t, fn, done)
  local n = #t
  if n == 0 then
    return done(true)
  end
  local completed = 0
  local failed = false
  for i = 1, n do
    fn(function (ok, ...)
      if failed then return end
      if not ok then
        failed = true
        return done(ok, ...)
      end
      completed = completed + 1
      if completed == n then
        return done(true)
      end
    end, t[i], i)
  end
end

M.mapall = function (t, fn, done)
  local n = #t
  if n == 0 then
    return done(true, t)
  end
  local completed = 0
  local failed = false
  for i = 1, n do
    fn(function (ok, v)
      if failed then return end
      if not ok then
        failed = true
        return done(ok, v)
      end
      t[i] = v
      completed = completed + 1
      if completed == n then
        return done(true, t)
      end
    end, t[i], i)
  end
end

M.filterall = function (t, fn, done)
  local n = #t
  if n == 0 then
    return done(true, t)
  end
  local keep = {}
  local completed = 0
  local failed = false
  for i = 1, n do
    fn(function (ok, should_keep)
      if failed then return end
      if not ok then
        failed = true
        return done(ok, should_keep)
      end
      keep[i] = should_keep
      completed = completed + 1
      if completed == n then
        local j = 1
        for k = 1, n do
          if keep[k] then
            t[j] = t[k]
            j = j + 1
          end
        end
        for k = j, n do
          t[k] = nil
        end
        return done(true, t)
      end
    end, t[i], i)
  end
end

return M
