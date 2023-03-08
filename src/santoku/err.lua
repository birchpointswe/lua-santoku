local tup = require("santoku.tuple")
local co = require("santoku.co")

-- TODO: In some cases, it might make sense to
-- consider the onErr callback more as a
-- "finally" or similar. Not sure the right
-- word.
--
-- assert(err.pwrap(function (check)
--
--   local token = check
--     .err(403, "No session token")
--     .exists(util.get_token())
--
--   local id_user = check
--     .err(403, "No active user")
--     .okexists(db.get_token_user_id(token))
--
--   local todos = check
--     .err(500, "Couldn't get todos")
--     .ok(db.get_todos(id_user))
--
--   -- TODO: This should pass to the util.exit
--   -- "finally" callback
--   check.exit(200, todos:unwrap())
--
--   -- util.exit(200, todos:unwrap())
--
-- end, util.exit))

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
  local errs = tup(...)
  local wrapper = {
    err = function (...)
      return M.pwrapper(co, ...)
    end,
    exists = function (val, ...)
      if val ~= nil then
        return val, ...
      else
        return co.yield(errs(...))
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
        return co.yield(errs(...))
      end
    end,
    ok = function (ok, ...)
      if ok then
        return ...
      else
        return co.yield(errs(...))
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
  local ret
  local nxt = tup()
  while true do
    ret = tup(co.resume(cor, select(2, nxt())))
    local status = co.status(cor)
    if status == "dead" then
      break
    elseif status == "suspended" then
      nxt = tup(onErr(select(2, ret())))
      if not nxt() then
        ret = nxt
        break
      end
    end
  end
  return ret()
end

return M
