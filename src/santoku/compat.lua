-- TODO: Rename to "common"
-- TODO: Move most zero-dependency basic
-- utilities here
-- TODO: Add remaining lua version shims here

local M = {}

M._pack = function (...)
  return { n = select("#", ...), ... }
end

-- TODO: there is a way to do this without the if
-- statement for overlapping ranges in the same
-- array.
M._move = function (s, ss, se, ds, d)
	d = d or s
  if ss > ds then
    for i = ss, se do
      d[ds + i - ss] = s[i]
    end
  else
    for i = se, ss, -1 do
      d[ds + i - ss] = s[i]
    end
  end
	return d
end

M.pack = table.pack or M._pack -- luacheck: ignore
M.unpack = unpack or table.unpack -- luacheck: ignore
M.move = table.move or M._move -- luacheck: ignore

local unpackr
unpackr = function (t, i)
  if i == 1 then
    return t[i]
  else
    return t[i], unpackr(t, i - 1)
  end
end

M.unpackr = function (t)
  return unpackr(t, t.n)
end

M.noop = function () end

M.id = function (...)
  return ...
end

M.const = function (...)
  local args = M.pack(...)
  return function ()
    return M.unpack(args, 1, args.n)
  end
end

M.iscallable = function (f)
  if type(f) == "function" then
    return true
  elseif type(f) == "table" then
    local mt = getmetatable(f)
    return mt and M.iscallable(mt.__call)
  else
    return false
  end
end

return M
