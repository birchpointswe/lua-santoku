-- TODO: support jumping into live repl (with variables loaded by) on error or
-- at specific points (specified by <file>:<line>)

-- TODO: integrate coverage analysis here

local str = require("santoku.string")
local it = require("santoku.iter")
local fs = require("santoku.fs")

local line_cache = {}
local name_cache = {}

local trace = function (_, line)
  local i = debug.getinfo(2, "Sn")
  local source = i.source and str.match(i.source, "^@(.*)")
  if source then
    local ls = line_cache[source]
    if not ls then
      ls = it.collect(fs.lines(source))
      line_cache[source] = ls
    end
    local bn = name_cache[source]
    if not bn then
      bn = fs.basename(source)
      name_cache[bn] = bn
    end
    if line then
      str.printf("%20s  %4d  %s\n", bn, line, ls[line])
    elseif i.name then
      str.printf("%20s  %4s  %s\n", bn, "", i.name)
    end
  end
end

return function ()
  debug.sethook(trace, "rl")
  return function ()
    debug.sethook()
  end
end
