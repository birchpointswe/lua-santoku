local arr = require("santoku.array")
local str = require("santoku.string")
local err = require("santoku.error")
local fun = require("santoku.functional")
local utc = require("santoku.utc")
local vdt = require("santoku.validate")

local time = utc.time
local noop = fun.noop
local hascall = vdt.hascall
local isstring = vdt.isstring

local running = coroutine.running
local setmetatable = setmetatable
local pairs = pairs

local WEAK = { __mode = "k" }
local MAIN = {}
local HEAD = "%10s %10s %10s %10s %10s %8s  %s"
local ROW = "%10.3f %10.3f %10.3f %10.3f %10.3f %8d  %s"

local enabled = false
local started = time(true)
local stats = {}
local stacks = setmetatable({}, WEAK)

local function zero (st)
  st.calls = 0
  st.total = 0
  st.self = 0
  st.min = 0
  st.max = 0
  st.open = 0
  st.unwound = 0
  return st
end

local function stat (label)
  local st = stats[label]
  if not st then
    st = zero({ label = label })
    stats[label] = st
  end
  return st
end

local function stack ()
  local co = running() or MAIN
  local s = stacks[co]
  if not s then
    s = { n = 0 }
    stacks[co] = s
  end
  return s
end

local function enter (s, st, fn)
  local d = s.n + 1
  local i = d * 4
  s.n = d
  s[i - 3] = st
  s[i - 2] = 0
  s[i - 1] = fn
  st.open = st.open + 1
  s[i] = time(true)
  return d
end

local function pop (s)
  local n = s.n
  local i = n * 4
  local st = s[i - 3]
  s.n = n - 1
  s[i - 3] = false
  s[i - 1] = false
  st.open = st.open - 1
  return st, i
end

local function close (s, now)
  local st, i = pop(s)
  local total = now - s[i]
  st.calls = st.calls + 1
  st.total = st.total + total
  st.self = st.self + total - s[i - 2]
  if s.n > 0 then
    s[i - 6] = s[i - 6] + total
  end
  if st.calls == 1 or total < st.min then
    st.min = total
  end
  if total > st.max then
    st.max = total
  end
end

local function drop (s)
  local st = pop(s)
  st.unwound = st.unwound + 1
end

local function exit (s, d)
  local now = time(true)
  if s.n < d then
    return err.error("profile: span finished out of order", d, s.n)
  end
  while s.n > d do
    drop(s)
  end
  close(s, now)
end

local function leave (s, d, ...)
  exit(s, d)
  return ...
end

local function span (label)
  if not enabled then
    return noop
  end
  local s = stack()
  local d = enter(s, stat(label), false)
  return function ()
    return exit(s, d)
  end
end

local function timed (label, fn, ...)
  if not enabled then
    return fn(...)
  end
  local s = stack()
  local d = enter(s, stat(label), false)
  return leave(s, d, fn(...))
end

local function wrapped (label, fn)
  err.assert(hascall(fn), "profile.wrapped: not callable", label)
  local st = stat(label)
  return function (...)
    if not enabled then
      return fn(...)
    end
    local s = stack()
    local d = enter(s, st, false)
    return leave(s, d, fn(...))
  end
end

local function wrap (t, names, prefix)
  prefix = prefix or ""
  if isstring(names) then
    names = { names }
  end
  for i = 1, #names do
    local k = names[i]
    t[k] = wrapped(prefix .. k, t[k])
  end
  return t
end

local function enable ()
  if enabled then
    return
  end
  started = time(true)
  enabled = true
end

local function disable ()
  enabled = false
end

local function isenabled ()
  return enabled
end

local function reset ()
  for _, st in pairs(stats) do
    zero(st)
  end
  stacks = setmetatable({}, WEAK)
  started = time(true)
end

local function elapsed ()
  return time(true) - started
end

local function report ()
  local r = {}
  for _, st in pairs(stats) do
    if st.calls > 0 or st.open ~= 0 or st.unwound > 0 then
      local mean = 0
      if st.calls > 0 then
        mean = st.total / st.calls
      end
      arr.push(r, {
        label = st.label,
        calls = st.calls,
        total = st.total,
        self = st.self,
        mean = mean,
        min = st.min,
        max = st.max,
        open = st.open,
        unwound = st.unwound,
      })
    end
  end
  return arr.sort(r, function (a, b)
    return a.self > b.self
  end)
end

local function format (r)
  r = r or report()
  local out = { str.format(HEAD, "self(ms)", "total(ms)", "mean(ms)", "min(ms)", "max(ms)", "calls", "label") }
  for i = 1, #r do
    local d = r[i]
    local label = d.label
    if d.open ~= 0 then
      label = str.format("%s open=%d", label, d.open)
    end
    if d.unwound ~= 0 then
      label = str.format("%s unwound=%d", label, d.unwound)
    end
    arr.push(out, str.format(ROW,
      d.self * 1000, d.total * 1000, d.mean * 1000,
      d.min * 1000, d.max * 1000, d.calls, label))
  end
  arr.push(out, str.format("%10.3f %10s  %s", elapsed() * 1000, "", "elapsed"))
  return arr.concat(out, "\n")
end

return {
  enable = enable,
  disable = disable,
  enabled = isenabled,
  reset = reset,
  span = span,
  timed = timed,
  wrap = wrap,
  wrapped = wrapped,
  elapsed = elapsed,
  report = report,
  format = format,
}
