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
  local errs = utils.tuple(...)
  local wrapper = {
    err = function (...)
      return M.pwrapper(co, ...)
    end,
    exists = function (val, ...)
      local args = utils.tuple(...)
      if val ~= nil then
        return val, ...
      else
        local allargs = utils.tuples(errs, args)
        return co.yield(allargs())
      end
    end,
    ok = function (ok, ...)
      local args = utils.tuple(...)
      if ok then
        return ...
      else
        local allargs = utils.tuples(errs, args)
        return co.yield(allargs())
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
  local err, n = utils.tuple(co.wrap(function ()
    run(M.pwrapper(co))
  end)())
  if n ~= 0 then
    if onErr == error then
      return onErr((select(2, err)))
    else
      return onErr(err())
    end
  end
end

return M
