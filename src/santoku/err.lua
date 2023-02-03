local vec = require("santoku.vector")
local compat = require("santoku.compat")
local co = require("santoku.co")

-- TODO: pwrap should be renamed to check, and
-- should work like a derivable/configurable
-- error handler:
--
-- err.pwrap(function (check)
--
--  check
--    :err("some err")
--    :exists()
--    :catch(function ()
--      "override handler", ...
--    end)
--    :ok(somefun())
--
-- end, function (...)
--
--  print("default handler", ...)
--
-- end)

local M = {}

M.unimplemented = function (msg)
  M.error("Unimplemented", msg)
end

M.error = function (...)
  error(table.concat({ ... }, ": "), 2)
end

M.pwrapper = function (co, ...)
  local errs = vec(...)
  local args = vec()
  local nargs = 0
  local wrapper = {
    err = function (...)
      return M.pwrapper(co, ...)
    end,
    exists = function (val, ...)
      if val ~= nil then
        return val, ...
      else
        args:trunc():append(...)
        errs:trunc(errs.n - nargs):extend(args)
        nargs = args.n
        return co.yield(errs:unpack())
      end
    end,
    -- TODO: Allow exists to be stacked with ok
    -- like:
    --   check
    --     .err("some err")
    --     .exists()
    --     .ok(somefunction())
    okexists = function (ok, val, ...)
      if ok and val ~= nil then
        return val, ...
      else
        args:trunc():append(...)
        errs:trunc(errs.n - nargs):extend(args)
        nargs = args.n
        return co.yield(errs:unpack())
      end
    end,
    ok = function (ok, ...)
      if ok then
        return ...
      else
        args:trunc():append(...)
        errs:trunc(errs.n - nargs):extend(args)
        nargs = args.n
        return co.yield(errs:unpack())
      end
    end
  }
  return setmetatable(wrapper, {
    __call = function (_, ...)
      return wrapper.ok(...)
    end
  })
end

-- TODO: Allow user to specify whether unchecked
-- are re-thrown or returned via the boolean,
-- ..vals mechanism
-- TODO: Pick an error level that makes errors
-- more readable
-- TODO: Reduce table creations with vec reuse
-- TODO: Allow user to specify coroutine
-- implementation
M.pwrap = function (run, onErr)
  onErr = onErr or function (...)
    return false, ...
  end
  local co = co()
  local cor = co.create(function ()
    return run(M.pwrapper(co))
  end)
  local ret = vec()
  local nxt = vec()
  while true do
    ret:trunc():append(co.resume(cor, nxt:unpack(2)))
    local status = co.status(cor)
    if status == "dead" then
      break
    elseif status == "suspended" then
      nxt:trunc():append(onErr(ret:unpack(2)))
      if not nxt[1] then
        ret = nxt
        break
      end
    end
  end
  return ret:unpack()
end

return M
