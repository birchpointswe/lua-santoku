-- TODO: Currently, child templates are compiled
-- when parent templates are rendered. We should
-- compile all the way down so that the
-- rendering step doesn't require child
-- compilations

-- TODO: Add input validation, istemplate, etc
-- TODO: Allow line prefixes (like comments) to
-- be ignored
-- TODO: Allow specifying filter for render/copy

-- TODO: Auto-indent lines based on parent
-- indent

local str = require("santoku.string")
local err = require("santoku.err")
local inherit = require("santoku.inherit")
local vec = require("santoku.vector")
local tup = require("santoku.tuple")
local fs = require("santoku.fs")
local compat = require("santoku.compat")

local M = {}

M.open = "<%"
M.close = "%>"

M.STR = tup()
M.FN = tup()

-- TODO use inherit
M.istemplate = function (t)
  if type(t) ~= "table" then
    return false
  end
  return (getmetatable(t) or {}).__index == M
end

local function trimwhitespace (parts)
  local lefti, left, typ, right
  for righti = 1, parts.n do
    typ, right = parts[righti]()
    if typ == M.STR then
      if left then
        local leftspace = left:match("\n%s*$")
        local rightspace = right:match("^%s*")
        if leftspace and rightspace then
          left = left:sub(1, string.len(left) - string.len(leftspace))
          parts[lefti] = tup(M.STR, left)
        end
      end
      lefti = righti
      left = right
    end
  end
end

M.compile = function (tmpl, config)

  config = config or {}
  local fenv = {}

  local open = str.escape(config.open or M.open)
  local close = str.escape(config.close or M.close)
  local openlen = string.len(M.open)
  local closelen = string.len(M.close)
  local parts = vec()
  local pos, ss, se, es, ee
  pos = 0

  while true do
    ss, se = string.find(tmpl, open, pos)
    if not ss then
      local after = tmpl:sub(pos + closelen - 1)
      if string.len(after) > 0 then
        parts:append((tup(M.STR, after)))
      end
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
        if string.len(before) > 0 then
          parts:append((tup(M.STR, before)))
        end
        local code = tmpl:sub(se + openlen, es - closelen)
        local ok, fn, cd = compat.load(code, fenv)
        if not ok then
          return false, fn, cd
        else
          parts:append((tup(M.FN, fn)))
        end
        pos = ee
      end
    end
  end

  trimwhitespace(parts)

  return true, setmetatable({
    fenv = fenv,
    source = tmpl,
    config = config,
    parts = parts,
  }, {
    __index = M,
    __call = function (tmpl, ...)
      return tmpl:render(...)
    end
  })

end

M.render = function (tmpl, env, penv, output)
  assert(M.istemplate(tmpl))
  return err.pwrap(function (check)

    local output = output or vec()

    local rt; rt = {

      insert = function (ok, str, cd)
        -- luacheck: ignore
        if (ok == nil) then 
          -- do nothing
        elseif type(ok) == "string" then
          output:append(ok)
        elseif ok == true and type(str) ~= "string" then
          check(false, "expected a string, got: " .. type(str))
        elseif ok == true then 
          output:append(str)
        elseif ok == false then
          check(false, str, cd)
        else
          check(false, "expected string, boolean, or nil: got: " .. type(ok))
        end
      end,

      extend = function (fp, env)
        assert(type(fp) == "string")
        local data = check(fs.readfile(fp))
        local tpl = check(M.compile(data, tmpl.config))
        tpl:render(env, tmpl.fenv, output)
      end

    }

    if penv then
      inherit.pushindex(tmpl.fenv, penv)
      inherit.pushindex(tmpl.fenv, env or {})
    else
      inherit.pushindex(tmpl.fenv, rt)
      inherit.pushindex(tmpl.fenv, tmpl.config.env or {})
      inherit.pushindex(tmpl.fenv, env or {})
    end

    for i = 1, tmpl.parts.n do

      local typ, data = tmpl.parts[i]()

      if typ == M.STR then
        rt.insert(data)
      elseif typ == M.FN then
        check.noerr(rt.insert(data()))
      else
        error("this is a bug: chunk has an undefined type")
      end

    end

    if not penv then

      return output:concat()

    elseif output.n > 0 then

      local last = output[output.n]
      local trailing = last:match("\n[ ]*$")
      if trailing then
        output[output.n] = last:sub(1, string.len(last) - string.len(trailing))
      end

    end

  end)
end

return setmetatable(M, {
  __call = function (_, ...)
    return M.compile(...)
  end
})
