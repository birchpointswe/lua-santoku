local tbl = require("santoku.table")
local co = require("santoku.co")

local M = {}

M.unimplemented = function (msg)
  M.error("Unimplemented", msg)
end

M.error = function (...)
  error(table.concat({ ... }, ": "), 2)
end

M.pwrapper = function (co, ...)
  local errs = tbl.pack(...)
  local wrapper = {
    err = function (...)
      return M.pwrapper(co, ...)
    end,
    exists = function (val, ...)
      local args = tbl.pack(...)
      if val ~= nil then
        return val, ...
      else
        return co.yield(tbl():extend(errs, args))
      end
    end,
    ok = function (ok, ...)
      local args = tbl.pack(...)
      if ok then
        return ...
      else
        return co.yield(tbl():extend(errs, args))
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
  local err = tbl.pack(co.wrap(function ()
    run(M.pwrapper(co))
  end)())
  if err:len() ~= 0 then
    if onErr == error then
      return onErr(err[2])
    else
      return onErr(err:unpack())
    end
  end
end

return M
