local gen = require("santoku.gen")

local function markdownpre (el)
  return table.concat({ "\n```\n", el, "\n```\n" })
end

return function (...)
  return gen.pack(...)
    :map(markdownpre)
    :intersperse("\n\n")
    :vec()
    :concat()
end
