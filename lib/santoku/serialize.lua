-- NOTE: Adapted from:
-- https://github.com/luarocks/luarocks/blob/master/src/luarocks/persist.lua

local array = require("santoku.array")
local acat = array.concat
local apush = array.push
local gsub = string.gsub

local _serialize_table

local string_subs = { ["\n"] = "\\n", ["\r"] = "\\r", ["\""] = "\\\"" }

local function _serialize_value (out, v, level, nl, div, sep, seen)
  if type(v) == "table" then
    level = level or 0
    _serialize_table(out, v, level + 1, nl, div, sep, seen)
  elseif type(v) == "string" then
    apush(out, acat({ "\"", gsub(v, "[\"\r\n]", string_subs), "\"" }))
  else
    apush(out, tostring(v))
  end
end

local function _serialize_table_key_assignment (out, k, level, nl, div, sep, seen)
  apush(out, "[")
  _serialize_value(out, k, level, nl, div, nil, seen)
  apush(out, "]")
  apush(out, sep, "=", sep)
end

local function _serialize_table_contents (out, tbl, level, nl, div, sep, seen)
  local sep0 = nl
  local indentation = div
  local maxi = nil
  for i = 1, #tbl do
    local v = tbl[i]
    if v == nil then
      break
    end
    maxi = i
    apush(out, sep0)
    for _ = 1, level do
      apush(out, indentation)
    end
    _serialize_value(out, v, level, nl, div, sep, seen)
    sep0 = "," .. nl
  end
  for k, v in pairs(tbl) do
    if not (type(k) == "number" and maxi and k >= 1 and k <= maxi) then
      apush(out, sep0)
      for _ = 1, level do
        apush(out, indentation)
      end
      _serialize_table_key_assignment(out, k, level, nl, div, sep, seen)
      _serialize_value(out, v, level, nl, div, sep, seen)
      sep0 = "," .. nl
    end
  end
  if sep0 ~= nl then
    apush(out, nl)
    for _ = 1, level - 1 do
      apush(out, indentation)
    end
  end
end

_serialize_table = function (out, tbl, level, nl, div, sep, seen)
  if seen[tbl] then
    apush(out, "nil")
  else
    seen[tbl] = true
    apush(out, "{")
    _serialize_table_contents(out, tbl, level, nl, div, sep, seen)
    apush(out, "}")
  end
end

local function get_separators (minify)
  if minify then
    return "", "", ""
  else
    return "\n", "  ", " "
  end
end

local function serialize_table_contents (t, minify, seen)
  local nl, div, sep = get_separators(minify)
  local out = {}
  seen = seen or {}
  _serialize_table_contents(out, t, 1, nl, div, sep, seen)
  return acat(out)
end

local function serialize (t, minify, seen)
  local nl, div, sep = get_separators(minify)
  local out = {}
  seen = seen or {}
  _serialize_value(out, t, nil, nl, div, sep, seen)
  return acat(out)
end

return setmetatable({
  serialize = serialize,
  serialize_table_contents = serialize_table_contents,
}, {
  __call = function (_, ...)
    return serialize(...)
  end
})
