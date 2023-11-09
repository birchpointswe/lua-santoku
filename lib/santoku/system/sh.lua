local err = require("santoku.err")
local tup = require("santoku.tuple")
local gen = require("santoku.gen")
local vec = require("santoku.vector")
local str = require("santoku.string")

local pread = require("santoku.system.pread")

local function yield_results (yield, chunks, out)
  if not out then
    local res = chunks:concat()
    if res ~= "" then
      yield(true, res)
    end
  else
    local nlidx = out:find("\n")
    if nlidx then
      chunks:append(out:sub(1, nlidx - 1))
      yield(true, chunks:concat())
      chunks:trunc()
      out = out:sub(nlidx + 1)
      if out ~= "" then
        local outs = str.split(out, "\n")
        for i = 1, outs.n - 1 do
          yield(true, outs[i])
        end
        chunks:append(outs[outs.n])
      end
    else
      chunks:append(out)
    end
  end
end

local function process_events (yield, iter, chunks)
  while iter:step() do
    local ev, out, status = iter.val()
    if ev == "exit" and not (out == "exited" and status == 0) then
      yield(false, out, status)
      break
    elseif ev == "exit" then
      yield_results(yield, chunks)
      break
    elseif ev == "stdout" then
      yield_results(yield, chunks, out)
    else
      io.stderr:write(out)
    end
  end
end

return function (...)
  local args = tup(...)
  return err.pwrap(function (check)
    local iter = check(pread(args())):co()
    return gen(function (yield)
      local chunks = vec()
      process_events(yield, iter, chunks)
    end)
  end)
end
