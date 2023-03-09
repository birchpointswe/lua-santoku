-- TODO: Add input validation, istemplate, etc

local str = require("santoku.string")
local tbl = require("santoku.table")
local vec = require("santoku.vector")
local compat = require("santoku.compat")

local M = {}

-- TODO: Add a shortcut that prepends "return"
M.open = "<%"
M.close = "%>"

M.compile = function (tmpl, opts)
  opts = opts or {}
  -- TODO: Should anything be in env by default?
  local env = {}
  local open = str.escape(opts.open or M.open)
  local close = str.escape(opts.close or M.close)
  local openlen = string.len(M.open)
  local closelen = string.len(M.close)
  local interps = vec()
  local parts = vec()
  local ss, se, es, ee
  ee = 0
  while true do
    ss, se = string.find(tmpl, open, ee)
    if not ss then
      local after = tmpl:sub(ee + closelen - 1)
      parts:append(after)
      break
    else
      es, ee = string.find(tmpl, close, se)
      if not es then
        return false, table.concat({
          "Invalid template: expecting: ",
          M.close,
          " at position ",
          ss
        })
      else
        local before = tmpl:sub(1, ss - openlen + 1)
        local code = tmpl:sub(se + openlen, es - closelen)
        local ok, fn, cd = compat.load(code, env)
        if not ok then
          code = "return " .. code
          -- TODO: Since were re-trying with
          -- return, we throw away the original
          -- error. Perhaps we should keep it
          -- somehow? Might make debuggin
          -- easier.
          ok, fn, cd = compat.load(code, env)
        end
        if not ok then
          return false, fn, cd
        else
          parts:append(before, fn)
          interps:append(parts.n)
        end
      end
    end
  end
  return true, setmetatable({
    env = env,
    parts = parts,
    interps = interps
  }, {
    __index = M,
    __call = function (tmpl, ...)
      return tmpl:render(...)
    end
  })
end

-- TODO: Currently this modifies the original
-- parts table, making this not-repeatable. We
-- need to create a new table for table.concat
-- instead of re-using parts.
M.render = function (tmpl, env)
  tbl.assign(tmpl.env, env or {})
  local parts = vec():copy(tmpl.parts)
  local interps = tmpl.interps
  for i = 1, interps.n do
    parts[interps[i]] = parts[interps[i]]()
  end
  return table.concat(parts)
end

return setmetatable(M, {
  __call = function (_, ...)
    return M.compile(...)
  end
})
