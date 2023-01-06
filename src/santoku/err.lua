local utils = require("santoku.utils")
local co = require("santoku.co")

local M = {}

M.unimplemented = function (msg)
  M.error("Unimplemented", msg)
end

M.error = function (...)
  error(table.concat({ ... }, ": "), 2)
end

M.pwrapper = function (co, ...)
  local errs = utils.pack(...)
  local wrapper = {
    err = function (...)
      return M.pwrapper(co, ...)
    end,
    exists = function (val, ...)
      local args = utils.pack(...)
      if val ~= nil then
        return val, ...
      else
        return co.yield(utils.extendarg(errs, args))
      end
    end,
    ok = function (ok, ...)
      local args = utils.pack(...)
      if ok then
        return ...
      else
        return co.yield(utils.extendarg(errs, args))
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
  onErr = onErr or error
  local co = co.make()
  local err = utils.pack(co.wrap(function ()
    run(M.pwrapper(co))
  end)())
  if err.n ~= 0 then
    if onErr == error then
      return onErr(err[2])
    else
      return onErr(utils.unpack(err))
    end
  end
end

return M
