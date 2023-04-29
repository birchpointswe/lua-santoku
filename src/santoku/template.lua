-- TODO: Add input validation, istemplate, etc
-- TODO: Allow line prefixes (like comments) to
-- be ignored
-- TODO: Allow specifying filter for render/copy

-- TODO: Auto-indent lines based on parent
-- indent
-- TODO: Refactor/cleanup.

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
M.tagclose = "%"

M.STR = tup()
M.FN = tup()

M.istemplate = function (t)
  return inherit.hasindex(t, M)
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

M.compilefile = function (parent, ...)
  local args = tup(...)
  if not M.istemplate(parent) then
    args = tup(parent, args())
    parent = nil
  end
  return err.pwrap(function (check)
    local fp = args()
    local data = check(fs.readfile(fp))
    if parent then
      return check(parent:compile(data, select(2, args())))
    else
      return check(M.compile(data, select(2, args())))
    end
  end)
end

M.compile = function (parent, ...)
  local args = tup(...)
  return err.pwrap(function (check)

    local tmpl, config

    if not M.istemplate(parent) then
      tmpl, config = parent, args()
      parent = nil
    else
      tmpl, config = args(), parent.config
    end

    config = config or {}
    local fenv = {}

    if parent then
      inherit.pushindex(fenv, parent.fenv)
    else
      inherit.pushindex(fenv, config.env or {})
    end

    local open = str.escape(config.open or M.open)
    local close = str.escape(config.close or M.close)
    local tagclose = str.escape(config.tagclose or M.tagclose)

    -- TODO: string.len is definitely wrong since
    -- open and close are patterns. Instead, use
    -- (se - ss) and (ee - es).
    local openlen = string.len(M.open)
    local closelen = string.len(M.close)
    local tagcloselen = string.len(M.tagclose)

    local parts = vec()
    local pos, ss, se, es, ee
    pos = 0

    local deps = vec()

    local ret = setmetatable({
      fenv = fenv,
      source = tmpl,
      deps = deps,
      config = config,
      parent = parent,
      parts = parts,
    }, {
      __call = function (tmpl, ...)
        return tmpl:render(...)
      end
    })

    inherit.pushindex(ret, M)

    inherit.pushindex(ret, {
      compilefile = function (a, b, ...)
        if not M.istemplate(a) then
          deps:append(a)
        else
          deps:append(b)
        end
        return M.compilefile(a, b, ...)
      end
    })

    fenv.template = ret
    fenv.check = check

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
          check(false, table.concat({
            "Invalid template: expecting: ",
            M.close,
            " at position ",
            ss
          }))
        else
          local before = tmpl:sub(pos + 1, ss - openlen + 1)
          if string.len(before) > 0 then
            parts:append((tup(M.STR, before)))
          end
          local code = tmpl:sub(se + openlen - 1, es - closelen)
          local tag = code:match("^([%w%s_-]*)" .. tagclose)
          if tag then
            code = code:sub(string.len(tag) + tagcloselen + 1)
          end
          local ok, fn, cd = compat.load(code, fenv)
          if not ok then
            check(false, fn, cd)
          elseif tag == nil or tag == "render" then
            parts:append((tup(M.FN, fn)))
          elseif tag == "compile" then
            local res = tup(fn())
            local ok = res()
            -- luacheck: ignore
            if ok == nil then
              -- do nothing
            elseif type(ok) == "string" then
              parts:append((tup(M.STR, res())))
            elseif not ok then
              check(false, select(2, res))
            else
              parts:append((tup(M.STR, select(2, res))))
            end
          else
            check(false, "Invalid tag: " .. tag)
          end
          pos = ee
        end
      end
    end

    trimwhitespace(parts)

    return ret

  end)
end

M.renderfile = function (fp, config)
  return err.pwrap(function (check)
    local tpl = check(M.compilefile(fp, config))
    return check(tpl:render())
  end)
end

local function insert (output, ok, ...)
  -- luacheck: ignore
  if (ok == nil) then 
    -- do nothing
    return true
  elseif type(ok) == "string" then
    -- TODO: should we check that the remaining
    -- args are strings?
    output:append(ok, ...)
    return true
  elseif ok == true then 
    -- TODO: should we check that the remaining
    -- args are strings?
    output:append(...)
    return true
  elseif ok == false then
    return false, ...
  else
    return false, "expected string, boolean, or nil: got: " .. type(ok)
  end
end

M.render = function (tmpl, env)
  assert(M.istemplate(tmpl))
  return err.pwrap(function (check)

    tmpl.fenv.check = check

    local output = vec()

    inherit.pushindex(tmpl.fenv, env or {})

    for i = 1, tmpl.parts.n do
      local typ, data = tmpl.parts[i]()
      if typ == M.STR then
        check(insert(output, select(2, tmpl.parts[i]())))
      elseif typ == M.FN then
        check(insert(output, data()))
      else
        error("this is a bug: chunk has an undefined type")
      end
    end

    if tmpl.parent and output.n > 0 then
      local last = output[output.n]
      local trailing = last:match("\n%s*$")
      if trailing then
        output[output.n] = last:sub(1, string.len(last) - string.len(trailing))
      end
    end

    return output:concat()

  end)
end

return setmetatable(M, {
  __call = function (_, ...)
    return M.compile(...)
  end
})
