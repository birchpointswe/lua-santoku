local err = require("santoku.err")
local tup = require("santoku.tuple")
local gen = require("santoku.gen")

local unistd = require("posix.unistd")
local wait = require("posix.sys.wait")
local poll = require("posix.poll")

local function run_child (check, file, args, sr, sw, er, ew)
  check.exists(unistd.close(sr))
  check.exists(unistd.close(er))
  check.exists(unistd.dup2(sw, unistd.STDOUT_FILENO))
  check.exists(unistd.dup2(ew, unistd.STDERR_FILENO))
  local _, err, cd = unistd.execp(file, args)
  io.stderr:write(table.concat({ err, ": ", cd, "\n" }))
  io.stderr:flush()
  os.exit(1)
end

local function run_parent_loop (check, yield, opts, pid, fds, sr, er)
  while true do

    check.exists(poll.poll(fds))

    for fd, cfg in pairs(fds) do

      if cfg.revents.IN then
        local res = check.exists(unistd.read(fd, opts.bufsize))
        if fd == sr then
          yield("stdout", res)
        elseif fd == er then
          yield("stderr", res)
        else
          check(false, "Invalid state: fd neither sr nor er")
        end
      elseif cfg.revents.HUP then
        check.exists(unistd.close(fd))
        fds[fd] = nil
      end

      if not next(fds) then
        local _, reason, status = check.exists(wait.wait(pid))
        yield("exit", reason, status)
        return
      end

    end
  end
end

local function run_parent (check, opts, pid, sr, sw, er, ew)

  check.exists(unistd.close(sw))
  check.exists(unistd.close(ew))

  local fds = { [sr] = { events = { IN = true } },
                [er] = { events = { IN = true } } }

  return gen(function (yield)
    err.check(err.pwrap(function (check)
      return run_parent_loop(check, yield, opts, pid, fds, sr, er)
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
    local sr, sw = check.exists(unistd.pipe())
    local er, ew = check.exists(unistd.pipe())
    local pid = check.exists(unistd.fork())

    if pid == 0 then
      return run_child(check, file, args, sr, sw, er, ew)
    else
      return run_parent(check, opts, pid, sr, sw, er, ew)
    end

  end)
end
