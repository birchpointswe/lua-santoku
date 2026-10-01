-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023 Birch Point SWE

local function getindex (t)
  local tmeta = getmetatable(t)
  if not tmeta then
    return
  end
  return tmeta.__index
end

local function setindex (t, i)
  local mt = getmetatable(t)
  if not mt then
    mt = {}
    setmetatable(t, mt)
  end
  mt.__index = i
  return t
end

local function pushindex (t, i)
  if not i then
    return t
  end
  local tindex = getindex(t)
  setindex(t, i)
  if tindex and i ~= tindex then
    pushindex(i, tindex)
  end
  return t
end

local function popindex (t)
  local tindex = getindex(t)
  if not tindex then
    return
  else
    local iindex = getindex(tindex)
    setindex(t, iindex)
    return tindex
  end
end

local function hasindex (t, i)
  local tindex
  while true do
    tindex = getindex(t)
    if not tindex then
      return false
    elseif tindex == i then
      return true
    else
      t = tindex
    end
  end
end

return {
  pushindex = pushindex,
  popindex = popindex,
  getindex = getindex,
  setindex = setindex,
  hasindex = hasindex
}
