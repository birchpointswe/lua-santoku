local arglist = function (n)
  local args = {}
  for i = 1, n do
    args[i] = "arg" .. i
  end
  return table.concat(args, ",")
end

local tuple = {}

return function (...)
  local m = select("#", ...)
  if not tuple[m] then
    local args = arglist(m)
    tuple[m] = loadstring(table.concat({[[
      return function (]], args, [[)
        return function ()
          return ]], args, [[
        end
      end
    ]]}))()
  end
  return tuple[m](...)
end
