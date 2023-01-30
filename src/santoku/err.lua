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
  local wrapper = {
    err = function (...)
      return M.pwrapper(co, ...)
    end,
    exists = function (val, ...)
      local args = vec(...)
      if val ~= nil then
        return val, ...
      else
        return co.yield(vec():extend(errs, args):unpack())
      end
    end,
    -- TODO: Allow exists to be stacked with ok
    -- like:
    --   check
    --     .err("some err")
    --     .exists()
    --     .ok(somefunction())
    okexists = function (ok, val, ...)
      local args = vec(...)
      if ok and val ~= nil then
        return val, ...
      else
        return co.yield(vec():extend(errs, args):unpack())
      end
    end,
    ok = function (ok, ...)
      local args = vec(...)
      if ok then
        return ...
      else
        return co.yield(vec():extend(errs, args):unpack())
      end
    end
  }
  return setmetatable(wrapper, {
    __call = function (_, ...)
      return wrapper.ok(...)
    end
  })
end

-- TODO: allow error recovery and passing details to onErr
-- handler
-- TODO: pass uncaught errors to onErr
-- TODO: Pick an error level that makes errors
-- more readable
-- TODO: Reduce table creations with vec reuse
M.pwrap = function (run, onErr)
  onErr = onErr or function (...)
    return false, ...
  end
  local co = co.make()
  local cor = co.create(function ()
    return run(M.pwrapper(co))
  end)
  local ret
  local nxt = vec()
  while true do
    ret = vec(co.resume(cor, nxt:unpack()))
    local status = co.status(cor)
    if status == "dead" then
      break
    elseif status == "suspended" then
      ret = vec(onErr(ret:slice(2):unpack()))
      if ret[1] then
        nxt = ret:slice(2)
      else
        break
      end
    end
  end
  return ret:unpack()
end

return M
