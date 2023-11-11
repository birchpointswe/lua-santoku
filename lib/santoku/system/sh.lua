local err = require("santoku.err")
local tup = require("santoku.tuple")
local gen = require("santoku.gen")
local vec = require("santoku.vector")
local str = require("santoku.string")

local pread = require("santoku.system.pread")

local function yield_data_ (yield, ev, data, pid)
  if ev == "stdout" then
    if data ~= "" then
      yield(true, data, pid)
    end
  else
    io.stderr:write(data)
  end
end

local function yield_data (yield, chunks, ev, data, pid)
  local nlidx = data:find("\n")
  if nlidx then
    chunks:append(data:sub(1, nlidx - 1))
    yield_data_(yield, ev, chunks:concat(), pid)
    chunks:trunc()
    data = data:sub(nlidx + 1)
    if data ~= "" then
      local datas = str.split(data, "\n")
      for i = 1, datas.n - 1 do
        yield_data_(yield, ev, datas[i], pid)
      end
      chunks:append(datas[datas.n])
    end
  else
    chunks:append(data)
  end
end

local function yield_remaining (yield, chunks, pid)
  chunks.stdout:each(function (data)
    yield_data_(yield, "stdout", data, pid)
  end)
  chunks.stderr:each(function (data)
    yield_data_(yield, "stdout", data, pid)
  end)
end

local function process_events (yield, iter, chunks)
  local ev, reason, status, data, pid
  while iter:step() do
    ev, reason, status, pid = iter.val()
    if ev == "exit" and not (reason == "exited" and status == 0) then
      yield(false, reason, status, pid)
    elseif ev == "exit" then
      yield_remaining(yield, chunks[pid], pid)
    else
      ev, data, pid = iter.val()
      yield_data(yield, chunks[pid][ev], ev, data, pid)
    end
  end
end

return function (...)
  local args = tup(...)
  return err.pwrap(function (check)
    local iter, children, fds = check(pread(args()))
    return gen(function (yield)
      local chunks = children:reduce(function (chunks, child)
        chunks[child.pid] = { stdout = vec(), stderr = vec() }
        return chunks
      end, {})
      process_events(yield, iter:co(), chunks)
    end), children, fds
  end)
end
