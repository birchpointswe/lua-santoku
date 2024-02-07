-- NOTE: Adapted from:
-- https://github.com/luarocks/luarocks/blob/master/src/luarocks/persist.lua

local array = require("santoku.array")
local acat = array.concat
local apush = array.push
local gsub = string.gsub

local _serialize_table

local string_subs = { ["\n"] = "\\n", ["\r"] = "\\r", ["\""] = "\\\"" }

local function _serialize_value (out, v, level)
  if type(v) == "table" then
    level = level or 0
    _serialize_table(out, v, level + 1)
  elseif type(v) == "string" then
    apush(out, acat({ "\"", gsub(v, "[\"\r\n]", string_subs), "\"" }))
  else
    apush(out, tostring(v))
  end
end

local function _serialize_table_key_assignment (out, k, level)
  apush(out, "[")
  _serialize_value(out, k, level)
  apush(out, "]")
  apush(out, " = ")
end

local function _serialize_table_contents (out, tbl, level)
  local sep = "\n"
  local indentation = "  "
  local i = 1
  for k, v in pairs(tbl) do
    apush(out, sep)
    for _ = 1, level do
      apush(out, indentation)
    end
    if k == i then
      i = i + 1
    else
      _serialize_table_key_assignment(out, k, level)
    end
    _serialize_value(out, v, level)
    sep = ",\n"
  end
  if sep ~= "\n" then
    apush(out, "\n")
    for _ = 1, level - 1 do
      apush(out, indentation)
    end
  end
end

_serialize_table = function (out, tbl, level)
  apush(out, "{")
  _serialize_table_contents(out, tbl, level)
  apush(out, "}")
end

local function serialize_table_contents (t)
  local out = {}
  _serialize_table_contents(out, t, 1)
  return acat(out)
end

local function serialize (t)
  local out = {}
  _serialize_value(out, t)
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
