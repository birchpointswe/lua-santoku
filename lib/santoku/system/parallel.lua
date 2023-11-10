-- TODO: Use ring buffers instead of popping from beginning of vector
-- TODO: Stderr
-- TODO: Profiling
-- TODO: Simplify by blocking reads until delim?
-- TODO: Allow user to enable/disable stdin, stout, and stderr. For example,
-- enable stdin but print stdout/stderr to default, or enable stdout but not
-- stdin

local err = require("santoku.err")
local vec = require("santoku.vector")
local tup = require("santoku.tuple")
local str = require("santoku.string")
local compat = require("santoku.compat")

local unistd = require("posix.unistd")
local wait = require("posix.sys.wait")
local poll = require("posix.poll")

local DELIM = {}

local function run_child (child)
  assert(unistd.close(child.stdin[2]))
  assert(unistd.close(child.stdout[1]))
  -- assert(unistd.close(child.stderr[1]))
  assert(unistd.dup2(child.stdin[1], unistd.STDIN_FILENO))
  assert(unistd.dup2(child.stdout[2], unistd.STDOUT_FILENO))
  -- assert(unistd.dup2(child.stderr[2], unistd.STDERR_FILENO))
  local _, err, cd = unistd.execp(child.file, child.args)
  io.stderr:write(table.concat({ err, ": ", cd, "\n" }))
  io.stderr:flush()
  os.exit(1)
end

-- Write max from child.bufin to child stdin
local function write_child (check, state, child, fd)
  print("Write: 1")
  io.flush()
  if child.bufin.n > 0 then
    print("Write: 2")
    io.flush()
    local chunk = child.bufin[1] .. state.opts.delim
    print("Write: 3")
    io.flush()
    local written = check.exists(unistd.write(fd, chunk))
    print("Write: 4", written, chunk:gsub("\n", "\\n"))
    io.flush()
    if written < #chunk then
      print("Write: 5")
      io.flush()
      child.bufin[1] = chunk:sub(written + 1)
    else
      print("Write: 6")
      io.flush()
      child.bufin:remove(1, 1)
    end
  end
end

-- Read max into child.bufout
local function read_child (check, state, child, fd)
  print("Read Child: 1")
  io.flush()
  local data = check.exists(unistd.read(fd, state.opts.bufsize))
  print("Read Child: 2")
  io.flush()
  str.split(data, state.delim):each(function (chunk)
    print("Read Child: 3")
    io.flush()
    if chunk ~= "" then
      print("Read Child: 4")
      io.flush()
      child.bufout:append(chunk, DELIM)
    end
  end)
end

local function move_child_complete_chunks (state, child)
  local found = 0
  for i = 1, child.bufout.n do
    if child.bufout[i] == DELIM then
      state.bufout:append(child.bufout:concat("", found + 1, i - 1))
      found = i
    end
  end
  if found > 0 then
    child.bufout:remove(1, found)
  end
end

local function state_pop_complete_chunk (state)
  local _, i = state.bufin:find(function (chunk)
    return chunk == DELIM
  end)
  if i then
    local out = state.bufin:concat("", 1, i - 1)
    state.bufin:remove(1, i)
    if out ~= "" then
      return out
    end
  end
end

local MT_IDX = {}
local MT = { __index = MT_IDX }

MT_IDX.step = function (state)
  return err.pwrap(function (check)

    print("Step: 0")
    io.flush()

    -- Poll fds
    check.exists(poll.poll(state.fds, -1))

    print("Step: 1")
    io.flush()

    -- For each fd
    for fd, cfg in pairs(state.fds) do

      -- Get associate child
      local child = state.fd_child[fd]

      -- If writable and child.bufin has chunks
      if cfg.revents.OUT and child.bufin.n > 0 then

        print("Step: 2")
        io.flush()

        -- Write max from child.bufin
        write_child(check, state, child, fd)

        print("Step: 3")
        io.flush()

      -- Else if writable and state.bufin has complete chunks
      elseif cfg.revents.OUT then

        local chunk = state_pop_complete_chunk(state)

        print("Step: 4")
        io.flush()

        if chunk then

          print("Step: 5")
          io.flush()

          -- Move one complete from state.bufin to child.bufin
          child.bufin:append(chunk)

          print("Step: 6")
          io.flush()

          -- Write max from child.bufin
          write_child(check, state, child, fd)

          print("Step: 7")
          io.flush()

        end

      end

      -- Else if readable
      if cfg.revents.IN then

        print("Step: 8")
        io.flush()

        -- Read max into child.bufout
        read_child(check, state, child, fd)

        print("Step: 9")
        io.flush()

        -- Move completed chunks to state.bufout
        move_child_complete_chunks(state, child)

        print("Step: 10")
        io.flush()

      end

      -- Else if closed
      if cfg.revents.HUP then

        print("Step: 11")
        io.flush()

        -- TODO: Is this right? In what situations would it not be an error for
        -- the child to close a pipe? What if the child is neither producing
        -- output nor consuming input, but instead is just running some process?
        -- In this case, the child might close the pipe.
        check(false, "child closed pipe unexpectedly", child.pid, fd)

        print("Step: 12")
        io.flush()

        -- -- Close fd
        -- check.exists(unistd.close(fd))
        -- -- Remove from poll
        -- fds[fd] = nil

      end

      -- -- TODO: See above todo. If we expect children to close pipes, then we
      -- need to handle this case

      -- -- No more descriptors to read/write
      -- if not next(fds) then
      --   return shutdown_no_fds(state)
      -- end

    end

  end)
end

-- TODO: Refine pwrap so that we can create sub-checks instead of having to
-- write check.err(sent).exists(...). It would be nice to write:
--   check = check.err(sent)
--   check.exists(x)
--   check.exists(y)
-- Note that the second argument to pwrap allows errors to be intercepted and
-- then conditionally bubbled or not. We use check.err(sent) so that we can
-- specifically tag the potential errors that we don't want to bubble
local function done_child (child, errs)
  local sent = {}
  return err.pwrap(function (check)
    check.err(sent).exists(unistd.close(child.stdin[2]))
    check.err(sent).exists(unistd.close(child.stdout[1]))
  end, function (s, err, cd)
    io.flush()
    if s == sent then
      errs:append({ child.pid, err, cd })
      return true
    else
      return false, s, err, cd
    end
  end)
end

local function close_child (child, errs)
  local sent = {}
  return err.pwrap(function (check)
    -- check.err(sent).exists(unistd.close(child.stderr[1]))
    -- TODO: Should we kill? How do we know the child will close when the pipes
    -- close?
    local _, reason, status = check.err(sent).exists(wait.wait(child.pid))
    if not (reason == "exited" and status == 0) then
      check(false, sent, reason, status)
    end
  end, function (s, err, cd)
    if s == sent then
      errs:append({ child.pid, err, cd })
      return true
    else
      return false, s, err, cd
    end
  end)
end

MT_IDX.done = function (state)
  assert(compat.hasmeta(state, MT))
  return err.pwrap(function (check)
    local errs = vec()
    state.children:each(function (child)
      check(done_child(child, errs))
    end)
    if errs.n > 0 then
      check(false, "errors closing children pipes", errs)
    end
  end)
end

MT_IDX.close = function (state)
  assert(compat.hasmeta(state, MT))
  return err.pwrap(function (check)
    local errs = vec()
    state.children:each(function (child)
      check(close_child(child, errs))
    end)
    if errs.n > 0 then
      check(false, "errors waiting for children to terminate", errs)
    end
  end)
end

local function pop_output_chunk (state)
  if state.bufout.n > 0 then
    local out = state.bufout[1]
    state.bufout:remove(1, 1)
    return out
  end
end

MT_IDX.read = function (state)
  assert(compat.hasmeta(state, MT))
  return err.pwrap(function (check)
    print("Read: 1")
    io.flush()
    check(state:step())
    local out = pop_output_chunk(state)
    print("Read: 2")
    io.flush()
    if out then
      print("Read: 3")
      io.flush()
      return out
    end
    print("Read: 4")
    io.flush()
  end)
end

MT_IDX.write = function (state, data)
  assert(compat.hasmeta(state, MT))
  assert(compat.istype(data, "nil", "string"))
  if data then
    str.split(data, state.opts.delim):each(function (chunk)
      state.bufin:append(chunk, DELIM)
    end)
  end
end

local function parent_state_machine (check, opts, children, fd_child, fds)
  return setmetatable({
    check = check,
    opts = opts,
    children = children,
    fd_child = fd_child,
    fds = fds,
    bufin = vec(),
    bufout = vec(),
  }, MT)
end

local function run_parent (check, opts, children, fd_child)

  local fds = {}

  children:each(function (child)
    check.exists(unistd.close(child.stdin[1]))
    check.exists(unistd.close(child.stdout[2]))
    -- check.exists(unistd.close(child.stderr[2]))
    fds[child.stdin[2]] = { events = { OUT = true } }
    fds[child.stdout[1]] = { events = { IN = true } }
    -- fds[child.stderr[1]] = { events = { IN = true } }
  end)

  return parent_state_machine(check, opts, children, fd_child, fds)

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

  -- TODO: What is the right bufsize?
  opts.bufsize = opts.bufsize or 4096
  opts.jobs = opts.jobs or 1
  opts.delim = opts.delim or "\n"
  opts.delim = str.escape(opts.delim)

  return err.pwrap(function (check)

    io.flush()

    local fd_child = {}
    local children = vec()

    for _ = 1, opts.jobs do

      local child = {
        file = file,
        args = args,
        stdin = { check.exists(unistd.pipe()) },
        stdout = { check.exists(unistd.pipe()) },
        -- stderr = { check.exists(unistd.pipe()) },
        bufin = vec(),
        bufout = vec(),
        -- buferr = vec(),
        pid = check.exists(unistd.fork()),
      }

      fd_child[child.stdin[1]] = child
      fd_child[child.stdin[2]] = child
      fd_child[child.stdout[1]] = child
      fd_child[child.stdout[2]] = child
      children:append(child)

      if child.pid == 0 then
        return run_child(child)
      end

    end

    return run_parent(check, opts, children, fd_child)

  end)
end
