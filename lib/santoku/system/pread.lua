-- TODO: Allow injecting different arguments to different jobs
-- TODO: Signal handlers for child process exits
-- TODO: Infinite hang when calling the generator after it has finished, likely
-- due to poll being called on no fds

local err = require("santoku.err")
local vec = require("santoku.vector")
local tup = require("santoku.tuple")
local gen = require("santoku.gen")

local unistd = require("posix.unistd")
local wait = require("posix.sys.wait")
local poll = require("posix.poll")
local fcntl = require("posix.fcntl")
local errno = require("posix.errno")
local bit = require("bit32")

local function run_child (file, args, child)
  assert(unistd.close(child.stdout.read))
  assert(unistd.close(child.stderr.read))
  assert(unistd.dup2(child.stdout.write, unistd.STDOUT_FILENO))
  assert(unistd.dup2(child.stderr.write, unistd.STDERR_FILENO))
  local _, err, cd = unistd.execp(file, args)
  io.stderr:write(table.concat({ err, ": ", cd, "\n" }))
  os.exit(1)
end

local function read_fd (check, opts, fd)
  local bytes, err, cd = unistd.read(fd, opts.bufsize)
  if bytes ~= nil then
    return bytes
  elseif bytes == nil and cd == errno.EAGAIN then
    return nil
  else
    return check(false, err, cd)
  end
end

local function run_parent_loop (check, yield, opts, children, fds)
  while true do

    check.exists(poll.poll(fds, opts.block == false and 0 or -1))

    for fd, cfg in pairs(fds) do

      -- TODO: Use a table lookup
      local child = children:find(function (child)
        return fd == child.stdout.read or
               fd == child.stderr.read
      end)

      if cfg.revents.IN then
        local res = read_fd(check, opts, fd)
        if fd == child.stdout.read then
          yield("stdout", res, child.pid)
        elseif fd == child.stderr.read then
          yield("stderr", res, child.pid)
        else
          check(false, "Invalid state: fd neither sr nor er")
        end
      elseif cfg.revents.HUP then
        check.exists(unistd.close(fd))
        fds[fd] = nil
      end

      if not next(fds) then
        local nexit = 0
        while nexit < children.n do
          local rc, reason, status = check.exists(wait.wait())
          nexit = nexit + 1
          if rc == 0 then
            break
          elseif rc < 0 then
            check(false, "Error waiting for child process", reason, status)
          else
            yield("exit", reason, status, child.pid)
          end
        end
        return
      end

    end
  end
end

local function run_parent (check, opts, children)

  local fds = {}

  children:each(function (child)
    check.exists(unistd.close(child.stdout.write))
    check.exists(unistd.close(child.stderr.write))
    fds[child.stdout.read] = { events = { IN = true } }
    fds[child.stderr.read] = { events = { IN = true } }
    if opts.block == false then
      local flags
      flags = check.exists(fcntl.fcntl(child.stdout.read, fcntl.F_GETFL, 0))
      check.exists(fcntl.fcntl(child.stdout.read, fcntl.F_SETFL, bit.bor(flags, fcntl.O_NONBLOCK)))
      flags = check.exists(fcntl.fcntl(child.stderr.read, fcntl.F_GETFL, 0))
      check.exists(fcntl.fcntl(child.stderr.read, fcntl.F_SETFL, bit.bor(flags, fcntl.O_NONBLOCK)))
    end
  end)

  return gen(function (yield)
    err.check(err.pwrap(function (check)
      return run_parent_loop(check, yield, opts, children, fds)
    end))
  end), children, fds

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
  opts.jobs = opts.jobs or 1

  return err.pwrap(function (check)

    io.flush()

    local children = vec()

    for _ = 1, opts.jobs do

      local sr, sw = check.exists(unistd.pipe())
      local er, ew = check.exists(unistd.pipe())
      local pid = check.exists(unistd.fork())

      local child = {
        pid = pid,
        stdout = { read = sr, write = sw },
        stderr = { read = er, write = ew },
      }

      if pid == 0 then
        return run_child(file, args, child)
      else
        children:append(child)
      end

    end

    return run_parent(check, opts, children)

  end)
end
