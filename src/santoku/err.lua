local utils = require("santoku.utils")
local co = require("santoku.co")

local M = {}

M.unimplemented = function (msg)
  local message = "Unimplemented"
  if msg then
    message = message .. ": " .. msg
  end
  error(message, 2)
end

M.error = function (...)
  error(table.concat({ ... }, ": "), 2)
end

M.pwrapper = function (coroutine, ...)
  local errs = utils.pack(...)
  local wrapper = {
    err = function (...)
      return M.pwrapper(coroutine, ...)
    end,
    exists = function (val, ...)
      local args = utils.pack(...)
      if val ~= nil then
        return val, ...
      else
        return coroutine.yield(utils.extendarg(errs, args))
      end
    end,
    ok = function (ok, ...)
      local args = utils.pack(...)
      if ok then
        return ...
      else
        return coroutine.yield(utils.extendarg(errs, args))
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
M.pwrap = function (run, onErr)
  local coroutine = co.make()
  local err = utils.pack(coroutine.wrap(function ()
    run(M.pwrapper(coroutine))
  end)())
  if err.n ~= 0 then
    return onErr(utils.unpack(err))
  end
end

return M
