local err = require("santoku.err")
local tup = require("santoku.tuple")
local gen = require("santoku.gen")

local unistd = require("posix.unistd")
local wait = require("posix.sys.wait")
local poll = require("posix.poll")

local function run_child (child)
  assert(unistd.close(child.stdout[1]))
  assert(unistd.close(child.stderr[1]))
  assert(unistd.dup2(child.stdout[2], unistd.STDOUT_FILENO))
  assert(unistd.dup2(child.stderr[2], unistd.STDERR_FILENO))
  local _, err, cd = unistd.execp(child.file, child.args)
  io.stderr:write(table.concat({ err, ": ", cd, "\n" }))
  io.stderr:flush()
  os.exit(1)
end

local function run_parent_loop (check, yield, opts, child, fds)
  while true do

    check.exists(poll.poll(fds))

    for fd, cfg in pairs(fds) do

      if cfg.revents.IN then
        local res = check.exists(unistd.read(fd, opts.bufsize))
        if fd == child.stdout[1] then
          yield("stdout", res)
        elseif fd == child.stderr[1] then
          yield("stderr", res)
        else
          check(false, "Invalid state: fd neither sr nor er")
        end
      elseif cfg.revents.HUP then
        check.exists(unistd.close(fd))
        fds[fd] = nil
      end

      if not next(fds) then
        local _, reason, status = check.exists(wait.wait(child.pid))
        yield("exit", reason, status)
        return
      end

    end
  end
end

local function run_parent (check, opts, child)

  check.exists(unistd.close(child.stdout[2]))
  check.exists(unistd.close(child.stderr[2]))

  local fds = { [child.stdout[1]] = { events = { IN = true } },
                [child.stderr[1]] = { events = { IN = true } } }

  return gen(function (yield)
    err.check(err.pwrap(function (check)
      return run_parent_loop(check, yield, opts, child, fds)
    end))
  end)

end

return function (...)

  local opts, args, file

  if type((...)) == "table" then
    opts = tup.get(1, ...)
    file = tup.get(2, ...)
    args = { tup.sel(3, ...) }
  else
    opts = {}
    file = tup.get(1, ...)
    args = { tup.sel(2, ...) }
  end

  -- TODO: PIPE_BUF is probably not the best default
  opts.bufsize = opts.bufsize or unistd._PC_PIPE_BUF

  return err.pwrap(function (check)

    io.flush()

    local child = {
      file = file,
      args = args,
      stdout = { check.exists(unistd.pipe()) },
      stderr = { check.exists(unistd.pipe()) },
      pid = check.exists(unistd.fork())
    }

    if child.pid == 0 then
      return run_child(child)
    else
      return run_parent(check, opts, child)
    end

  end)
end
