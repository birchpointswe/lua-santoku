local inspect = require("inspect")
local gen = require("santoku.gen")

local function minspect (el)
  if type(el) == "string" then
    return el
  else
    return inspect(el, { 
      process = function (it, path)
        if path[#path] ~= inspect.METATABLE then 
          return it
        end
      end
    })
  end
end

return function (...)
  return gen.pack(...)
    :map(minspect)
    :intersperse("\n\n")
    :vec()
    :concat()
end
