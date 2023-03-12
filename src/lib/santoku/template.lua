-- TODO: Add input validation, istemplate, etc
-- TODO: Allow line prefixes (like comments) to
-- be ignored
-- TODO: Allow specifying filter for render/copy

-- TODO: Auto-indent lines based on parent
-- indent  

-- TODO: Removing trailing newlines doesn't work
-- as expected with some html:
--
--    <title>
--      <% return title %>
--    <title>
--
-- ...ends up as:
--
--    <title>
--      Some title<title>

local str = require("santoku.string")
local err = require("santoku.err")
local inherit = require("santoku.inherit")
local vec = require("santoku.vector")
local fs = require("santoku.fs")
local compat = require("santoku.compat")

local M = {}

M.open = "<%"
M.close = "%>"

-- TODO use inherit
M.istemplate = function (t)
  if type(t) ~= "table" then
    return false
  end
  return (getmetatable(t) or {}).__index == M
end

-- TODO skipenv is used to ignore the
-- setting fenv's index to config.env. This is
-- used when extending templates to prevent a
-- loop in indexes. We can remove the need for
-- skipenv by either not passing the parent
-- config into the child compile call or by
-- splitting config.env into a separate
-- argument.
M.compile = function (tmpl, config, skipenv)

  config = config or {}
  local fenv = {}

  local open = str.escape(config.open or M.open)
  local close = str.escape(config.close or M.close)
  local openlen = string.len(M.open)
  local closelen = string.len(M.close)
  local interps = vec()
  local parts = vec()
  local pos, ss, se, es, ee
  pos = 0

  while true do
    ss, se = string.find(tmpl, open, pos)
    if not ss then
      local after = tmpl:sub(pos + closelen - 1)
      local trailing = after:match("^\n[ ]*")
      if trailing then
        after = after:sub(string.len(trailing) + 1)
      end
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
        local before = tmpl:sub(pos + 1, ss - openlen + 1)
        local code = tmpl:sub(se + openlen, es - closelen)
        local ok, fn, cd = compat.load(code, fenv)
        if not ok then
          return false, fn, cd
        else
          pos = ee
          parts:append(before, fn)
          interps:append(parts.n)
        end
      end
    end
  end

  local ret = setmetatable({
    fenv = fenv,
    config = config,
    parts = parts,
    interps = interps
  }, {
    __index = M,
    __call = function (tmpl, ...)
      return tmpl:render(...)
    end
  })

  fenv.template = ret
  if not skipenv then
    inherit.pushindex(fenv, config.env)
  end
  return true, ret
end

M.render = function (tmpl, config)
  assert(M.istemplate(tmpl))
  if config and config.env then
    inherit.pushindex(tmpl.fenv, config.env)
  end
  local parts = vec():copy(tmpl.parts)
  local interps = tmpl.interps
  for i = 1, interps.n do
    local ok, str, cd = parts[interps[i]]()
    if ok == nil then
      parts[interps[i]] = ""
    elseif type(ok) == "string" then
      parts[interps[i]] = ok
    elseif ok == true then
      parts[interps[i]] = str
    elseif ok == false then
      if config and config.env then
        inherit.popindex(tmpl.fenv)
      end
      return false, str, cd
    else
      if config and config.env then
        inherit.popindex(tmpl.fenv)
      end
      return false, "expected string, boolean, or nil: got: " .. type(ok)
    end
  end
  if config and config.env then
    inherit.popindex(tmpl.fenv)
  end
  return true, table.concat(parts)
end

-- TODO: Currently this only allows overriding
-- the child environment. We should also allow
-- overriding open/close/etc
M.extend = function (tmpl, fp, env)
  assert(M.istemplate(tmpl))
  assert(type(fp) == "string")
  return err.pwrap(function (check)
    local data = check(fs.readfile(fp))
    local tpl = check(M.compile(data, tmpl.config, true))
    inherit.pushindex(tpl.fenv, tmpl.fenv)
    if env then
      inherit.pushindex(tpl.fenv, env)
    end
    local res = check(tpl:render())
    if env then
      inherit.popindex(tpl.fenv)
    end
    inherit.popindex(tpl.fenv)
    return res
  end)
end

return setmetatable(M, {
  __call = function (_, ...)
    return M.compile(...)
  end
})
