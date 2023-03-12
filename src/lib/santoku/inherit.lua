-- TODO: Basic inheritance logic
-- TODO: Should this be merged into utils?
-- TODO: Should this be called "meta" or
-- something related to metatables? Perhaps
-- "index"?

local M = {}

-- TODO: Like pushindex, except sub-tables in t
-- get indexes from the corresponding sub-tables
-- in i
M.mergeindex = function (t, i)
  error("mergeindex: unimplemented")
end

M.pushindex = function (t, i)
  assert(type(t) == "table")
  assert(t ~= i, "setting a table to its own index")
  if not i then
    return
  end
  assert(type(i) == "table")
  local tindex = M.getindex(t)
  M.setindex(t, i)
  if tindex and i ~= tindex then
    M.pushindex(i, tindex)
  end
end

M.popindex = function (t)
  assert(type(t) == "table")
  local tindex = M.getindex(t)
  if not tindex then
    return
  else
    local iindex = M.getindex(tindex)
    M.setindex(t, iindex)
    return tindex
  end
end

M.setindex = function (t, i)
  assert(type(t) == "table")
  local mt = getmetatable(t)
  if not mt then
    mt = {}
    setmetatable(t, mt)
  end
  mt.__index = i
end

M.getindex = function (t)
  local tmeta = getmetatable(t)
  if not tmeta then
    return
  end
  return tmeta.__index
end

M.hasindex = function (t, i)
  local tindex
  while true do
    tindex = M.getindex(t)
    if not tindex then
      return false
    elseif tindex == i then
      return true
    else
      t = tindex
    end
  end
end

return M
