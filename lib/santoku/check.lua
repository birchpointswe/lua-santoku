local tup = require("santoku.tuple")
local fun = require("santoku.fun")
local co = require("santoku.co")
local compat = require("santoku.compat")

local M = {}

M.error = function (_, ...)
  error(tup.concat(tup.interleave(": ", tup.map(tostring, ...))), 0)
end

M.check = function (_, ok, ...)
  if not ok then
    M:error(...)
  else
    return ...
  end
end

M.exists = function (_, ...)
  return M:check((...) ~= nil, ...)
end

local subcheck
subcheck = function (o, fn)

  local N = {}
  local o0 = {}

  o0.handler = fn or fun.bindl(compat.id, false)

  N.check = function (_, ...)
    return o.co.yield(o0, ...)
  end

  N.exists = function (_, ...)
    return o.co.yield(o0, (...) ~= nil, ...)
  end

  N.handler = function (n, fn)
    o0.handler = fn
    return n
  end

  N.sub = function (_, fn)
    return subcheck(o, fn)
  end

  return setmetatable(N, {
    __call = N.check
  })

end

M.wrap = function (_, run)

  local o = {}
  o.co = co()
  o.cor = o.co.create(run)

  local args = tup(subcheck(o))

  while true do
    local ret = tup(o.co.resume(o.cor, args()))
    if not ret() then
      return tup.sel(2, ret())
    elseif o.co.status(o.cor) == "dead" then
      return ret()
    elseif tup.sel(3, ret()) then
      args = tup(tup.sel(4, ret()))
    else
      local _, o0 = ret()
      local hret = tup(o0.handler(tup.sel(4, ret())))
      if hret() then
        args = tup(tup.sel(2, hret()))
      else
        return hret()
      end
    end
  end

end

return setmetatable(M, { __call = M.check })

-- local tup = require("santoku.tuple")
-- local co = require("santoku.co")
-- local fun = require("santoku.fun")
-- local compat = require("santoku.compat")
--
-- -- TODO: We need helper functions to chain
-- -- error-returning functions without resorting
-- -- to coroutines: something like:
-- --
-- --    local ok, val = err.pipe(input, fn1, fn2)
-- --
-- -- ...where fn1 takes "input" and produces a
-- -- boolean and a value, and fn2 takes that
-- -- value and produces another boolean and value.
-- -- Somehow we need to handle additional
-- -- arguments.
-- --
-- -- TODO: In some cases, it might make sense to
-- -- consider the onErr callback more as a
-- -- "finally" or similar. Not sure the right
-- -- word.
-- --
-- -- assert(err.pwrap(function (check)
-- --
-- --   local token = check
-- --     .err(403, "No session token")
-- --     .exists(util.get_token())
-- --
-- --   local id_user = check
-- --     .err(403, "No active user")
-- --     .okexists(db.get_token_user_id(token))
-- --
-- --   local todos = check
-- --     .err(500, "Couldn't get todos")
-- --     .ok(db.get_todos(id_user))
-- --
-- --   -- TODO: This should pass to the util.exit
-- --   -- "finally" callback
-- --   check.exit(200, todos:unwrap())
-- --
-- --   -- util.exit(200, todos:unwrap())
-- --
-- -- end, util.exit))
-- --
-- -- TODO: pwrap should be renamed to check, and
-- -- should work like a derivable/configurable
-- -- error handler:
-- --
-- -- err.pwrap(function (check)
-- --
-- --  check
-- --    :err("some err")
-- --    :exists()
-- --    :catch(function ()
-- --      "override handler", ...
-- --    end)
-- --    :ok(somefun())
-- --
-- -- end, function (...)
-- --
-- --  print("default handler", ...)
-- --
-- -- end)
-- --
-- -- TODO: Allow user to specify whether unchecked
-- -- are re-thrown or returned via the boolean,
-- -- ..vals mechanism
-- -- TODO: Pick an error level that makes errors
-- -- more readable
-- -- TODO: Reduce table creations with vec reuse
-- -- TODO: Allow user to specify coroutine
-- -- implementation
--
-- local M = {}
--
-- local IDX = {}
--
-- M.MT = {
--   __index = IDX,
--   __call = function (o, ...)
--     return o:ok(...)
--   end
-- }
--
-- IDX.tag = function (o, err_tag)
--   return M.pwrapper(o.co, err_tag)
-- end
--
-- IDX.ok = function (o, ok, ...)
--   if ok then
--     return ...
--   else
--     return o.co.yield(o.err_tag, ...)
--   end
-- end
--
-- IDX.exists = function (o, val, ...)
--   if val ~= nil then
--     return val, ...
--   else
--     return o.co.yield(o.err_tag, ...)
--   end
-- en
--
-- IDX.okexists = function (o, ok, val, ...)
--   if ok and val ~= nil then
--     return val, ...
--   else
--     return o.co.yield(o.err_tag, ...)
--   end
-- end
--
-- IDX.noerr = function (o, ok, ...)
--   if ok == false then
--     return o.co.yield(o.err_tag, ...)
--   else
--     return ...
--   end
-- end
--
-- M.pwrapper = function (co, err_tag)
--   return setmetatable({ co = co, err_tag = err_tag }, M.MT)
-- end
--
-- M.wrap = function (_, run, on_err)
--   on_err = on_err or fun.bindl(compat.id, false)
--   local co = co()
--   local cor = co.create(function ()
--     return run(M.pwrapper(co))
--   end)
--   local ret
--   local nxt = tup()
--   while true do
--     ret = tup(co.resume(cor, select(2, nxt())))
--     local status = co.status(cor)
--     if status == "dead" then
--       break
--     elseif status == "suspended" then
--       nxt = tup(on_err(select(2, ret())))
--       if not nxt() then
--         ret = nxt
--         break
--       end
--     end
--   end
--   return ret()
-- end
--
-- M.error = function (...)
--   error(tup.concat(tup.interleave(": ", tup.map(tostring, ...))), 0)
-- end
--
-- return setmetatable(M, {
--   __call = function (_, ok, ...)
--     if not ok then
--       M.error(...)
--     else
--       return ...
--     end
--   end
-- })
