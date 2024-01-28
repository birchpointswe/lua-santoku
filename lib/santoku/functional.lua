local compat = require("santoku.compat")
local hascall = compat.hasmeta.call
local cunpack = compat.unpack
local cid = compat.id

local arr = require("santoku.array")
local aextend = arr.extend
local apush = arr.push
local aspread = arr.spread
local amove = arr.move
local aoverlay = arr.overlay

local varg = require("santoku.varg")
local vsel = varg.sel

-- TODO: Can we do this without tables?
local function narg (...)
  local idx = { ... }
  return function (fn, ...)
    assert(hascall(fn))
    local bound = { ... }
    return function (...)
      local args = aextend({ ... }, bound)
      local nargs = {}
      for i = 1, #idx do
        amove(nargs, args, #nargs + 1, idx[i], idx[i])
      end
      amove(nargs, args)
      return fn(cunpack(nargs))
    end
  end
end

local function bindr (fn, ...)
  assert(hascall(fn))
  local args = { ... }
  return function (...)
    return fn(aspread(aextend({ ... }, args)))
  end
end

local function bindl (fn, ...)
  assert(hascall(fn))
  local args = { ... }
  return function (...)
    return fn(cunpack(apush(aextend({}, args), ...)))
  end
end

local function maybel (fn, ...)
  assert(hascall(fn))
  fn = bindl(fn or cid, ...)
  return function (ok, ...)
    if ok then
      return true, fn(...)
    else
      return false, ...
    end
  end
end

local function mayber (fn, ...)
  assert(hascall(fn))
  fn = bindr(fn or cid, ...)
  return function (ok, ...)
    if ok then
      return true, fn(...)
    else
      return false, ...
    end
  end
end

-- TODO: Use 0 to specify "rest": If its last,
-- append rest to the end, if it's first, append
-- rest to the "holes" left by the indices
local function nret (...)
  local idx = { ... }
  return function (...)
    local rets = {}
    for i = 1, #idx do
      local nret = vsel(idx[i], ...)
      rets[#rets + 1] = nret
    end
    return cunpack(rets)
  end
end

local function compose (...)
  local fns = { ... }
  return function(...)
    local args = { ... }
    for i = #fns, 1, -1 do
      assert(hascall(fns[i]))
      aoverlay(args, 1, fns[i](cunpack(args)))
    end
    return cunpack(args)
  end
end

local function sel (n, f)
  assert(hascall(f))
  return function (...)
    return f(vsel(n, ...))
  end
end

local function choose (a, b, c)
  if a then
    return b
  else
    return c
  end
end

return {
  narg = narg,
  bindr = bindr,
  bindl = bindl,
  maybel = maybel,
  mayber = mayber,
  nret = nret,
  compose = compose,
  sel = sel,
  choose = choose,
  bind = bindr,
  maybe = mayber,
}
