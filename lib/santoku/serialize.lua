-- NOTE: Adapted from:
-- https://github.com/luarocks/luarocks/blob/master/src/luarocks/persist.lua

local gen = require("santoku.gen")
local vec = require("santoku.vector")

local M = {}

M._serialize_table_contents = function (out, tbl, level)
  local sep = "\n"
  local indentation = "  "
  local i = 1
  gen.pairs(tbl):each(function (k, v)
    out:append(sep)
    for _ = 1, level do
      out:append(indentation)
    end
    if k == i then
      i = i + 1
    else
      M._serialize_table_key_assignment(out, k, level)
    end
    M._serialize_value(out, v, level)
    sep = ",\n"
  end)
  if sep ~= "\n" then
    out:append("\n")
    for _ = 1, level - 1 do
      out:append(indentation)
    end
  end
end

M._serialize_table = function (out, tbl, level)
  out:append("{")
  M._serialize_table_contents(out, tbl, level)
  out:append("}")
end

M._serialize_table_key_assignment = function (out, k, level)
  out:append("[")
  M._serialize_value(out, k, level)
  out:append("]")
  out:append(" = ")
end

M._serialize_value = function (out, v, level)
  if type(v) == "table" then
    level = level or 0
    M._serialize_table(out, v, level + 1)
  elseif type(v) == "string" then
    if v:match("[\r\n]") then
      local open = "[["
      local close = "]]"
      local equals = 0
      local v_with_bracket = v .. "]"
      while v_with_bracket:find(close, 1, true) do
        equals = equals + 1
        local eqs = ("="):rep(equals)
        open = "[" .. eqs .. "["
        close = "]" .. eqs .. "]"
      end
      out:append(open .. "\n" .. v .. close)
    else
      out:append(("%q"):format(v))
    end
  else
    out:append(tostring(v))
  end
end

M.serialize_table_contents = function (t)
  local out = vec()
  M._serialize_table_contents(out, t, 1)
  return out:concat()
end

M.serialize = function (t)
  local out = vec()
  M._serialize_value(out, t)
  return out:concat()
end

return setmetatable(M, {
  __call = function (_, ...)
    return M.serialize(...)
  end
})
