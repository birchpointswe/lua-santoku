-- TODO: Rename to "common", since this is more
-- than a compatibility layer
-- TODO: Add package.searchpath shim
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

-- TODO: Extend to account for numbers, etc.
-- compat.hasmeta.add(1) should be true.
-- compat.hasmeta.concat("hi") should be true.
--
-- TODO: There must be some bugs hidden in
-- this..
M.hasmeta = setmetatable({}, {
  __index = function (_, k)
    k = "__" .. k
    return function (o)
      local mt = getmetatable(o)

      if (mt and mt[k] ~= nil) or

         -- TODO: Can we check without calling?
         (k == "__pairs" and pcall(pairs, o)) or
         (k == "__ipairs" and pcall(ipairs, o)) or

         -- TODO: Are these necessary?
         (k == "__newindex" and type(o) == "table") or
         (k == "__index" and (type(o) == "table" or
                              type(o) == "string")) or


         (k == "__call" and type(o) == "function") or

         (k == "__len" and (type(o) == "string" or
                            type(o) == "table")) or

         (k == "__tostring" and (type(o) == "string" or
                                 type(o) == "number")) or

         (k == "__concat" and (type(o) == "string" or
                               type(o) == "number")) or

         (k == "__add" and type(o) == "number") or
         (k == "__sub" and type(o) == "number") or
         (k == "__mul" and type(o) == "number") or
         (k == "__div" and type(o) == "number") or
         (k == "__mod" and type(o) == "number") or
         (k == "__pow" and type(o) == "number") or
         (k == "__unm" and type(o) == "number") or
         (k == "__idiv" and type(o) == "number") or
         (k == "__band" and type(o) == "number") or
         (k == "__bor" and type(o) == "number") or
         (k == "__bxor" and type(o) == "number") or
         (k == "__bnot" and type(o) == "number") or
         (k == "__shl" and type(o) == "number") or
         (k == "__shr" and type(o) == "number") or

         (k == "__eq" and true) or
         (k == "__ne" and M.hasmeta.eq(o)) or

         (k == "__lt" and (type(o) == "number" or
                           type(o) == "string")) or

         (k == "__le" and (type(o) == "number" or
                           type(o) == "string")) or

         (k == "__gt" and M.hasmeta.lt(o)) or
         (k == "__ge" and M.hasmeta.le(o))

      then
        return true
      else
        return false, "missing metamethod: " .. k
      end

    end
  end
})

M.isarray = function (t)
  if type(t) ~= "table" then
    return false
  end
  local i = 0
  for k, v in pairs(t) do
    if k == "n" and type(v) == "number" then -- luacheck: ignore
      -- continue
    else
      i = i + 1
      if t[i] == nil then
        return false
      end
    end
  end
  return true
end

M.load = function (code, env)
  if setfenv and loadstring then -- luacheck: ignore
    local f, err, cd = loadstring(code) -- luacheck: ignore
    if not f then
      -- TODO: Add better messages
      return false, err, cd
    else
      if env then
        -- TODO: Can we catch an error here?
        setfenv(f, env) -- luacheck: ignore
      end
      return true, f
    end
  else
    local f, err, cd = load(code, nil, "t", env)
    if not f then
      return false, err, cd
    else
      return true, f
    end
  end
end

return M
