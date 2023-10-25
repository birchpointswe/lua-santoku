-- TODO: Consider disallowing bool + string
-- returns, and instead just return strings
-- directly. This will make formatters easier to
-- implement.
--
-- TODO: Add input validation, istemplate, etc
-- TODO: Allow line prefixes (like comments) to
-- be ignored
-- TODO: Allow specifying filter for render/copy

-- TODO: Auto-indent lines based on parent
-- indent
-- TODO: Refactor/cleanup.

local str = require("santoku.string")
local op = require("santoku.op")
local err = require("santoku.err")
local inherit = require("santoku.inherit")
local vec = require("santoku.vector")
local gen = require("santoku.gen")
local tup = require("santoku.tuple")
local fs = require("santoku.fs")
local compat = require("santoku.compat")

local M = {}

M.MT = {
  __call = function (_, ...)
    return M.compile(...)
  end
}

M.MT_TEMPLATE = {
  __name = "santoku_template",
  __index = function (tmpl, k)
    return tmpl.index[k]
  end,
  __call = function (tmpl, ...)
    return tmpl:render(...)
  end
}

M.open = "<%"
M.close = "%>"
M.tagclose = "%"

M.STR = {}
M.FN = {}

M.istemplate = function (t)
  return compat.hasmeta(t, M.MT_TEMPLATE)
end

M.compiledir = function (parent, dir, opts)
  if not M.istemplate(parent) then
    opts = dir
    dir = parent
    parent = nil
  end
  opts = opts or {}
  if opts.trim == nil then
    opts.trim = true
  end
  return err.pwrap(function (check)
    local ret = {}
    fs.files(dir)
      :map(check)
      :map(function (fp)
        local ext = fs.extension(fp)
        return ext, fp
      end)
      :filter(function (ext)
        return not opts.exts or gen.vals(opts.exts):includes(ext)
      end)
      :each(function (ext, fp)
        local tmpl = parent
          and check(parent:compilefile(fp, opts.config))
          or check(M.compilefile(fp, opts.config))
        if opts.trim then
          fp = str.stripprefix(fp, dir)
          fp = fp:match("^" .. str.escape(fs.pathdelim) .. "*(.*)$")
        end
        local name = fs.splitexts(fp).name
        ret[ext] = ret[ext] or {}
        ret[ext][name] = tmpl
      end)
    return ret
  end)
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
      return check(parent:compile(data, tup.sel(2, args())))
    else
      return check(M.compile(data, tup.sel(2, args())))
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
    local showstack = vec(true)

    local ret = setmetatable({
      index = {},
      fenv = fenv,
      source = tmpl,
      deps = deps,
      showstack = showstack,
      config = config,
      parent = parent,
      parts = parts,
    }, M.MT_TEMPLATE)

    inherit.pushindex(ret.index, M)

    inherit.pushindex(ret.index, {
      push = function (t, tf)
        assert(M.istemplate(t), "first argument to push must be a template")
        assert(type(tf) == "boolean", "second argument to push must be a boolean")
        t.showstack:push(tf)
        return t
      end,
      pop = function (t)
        assert(M.istemplate(t), "first argument to push must be a template")
        showstack:pop()
        return t
      end,
      showing = function (t)
        assert(M.istemplate(t), "first argument to showing must be a template")
        return gen.nvals(t.showstack, -1):co():find(op["not"]) ~= false
      end,
      compiledir = M.compiledir,
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
            if ok == nil then -- luacheck: ignore
              -- do nothing
            elseif type(ok) == "string" then
              parts:append((tup(M.STR, res())))
            elseif not ok then
              check(false, tup.sel(2, res))
            else
              parts:append((tup(M.STR, tup.sel(2, res))))
            end
          else
            check(false, "Invalid tag: " .. tag)
          end
          pos = ee
        end
      end
    end

    return ret

  end)
end

M.renderfile = function (fp, config)
  return err.pwrap(function (check)
    local tpl = check(M.compilefile(fp, config))
    return check(tpl:render())
  end)
end

M._should_insert = function (ok)
  return ok == true or type(ok) == "string"
end

M._get_prefix = function (data)

  if not data then
    return
  end

  local typ, data = data()

  if typ ~= M.STR then
    return
  end

  return data:match("\n([^\n]+)$") or data:match("^([^\n]+)$")

end

M._append_prefix = function (left, ...)

  local prefix = M._get_prefix(left)

  if not prefix then
    return ...
  end

  return tup.map(function (s)
    return (s:gsub("\n", "\n" .. prefix))
  end, ...)

end

M._insert = function (output, left, ok, ...)
  if (ok == nil) then -- luacheck: ignore
    -- do nothing
    return true
  elseif type(ok) == "string" then
    -- TODO: should we check that the remaining
    -- args are strings?
    output:append(M._append_prefix(left, ok, ...))
    return true
  elseif ok == true then
    -- TODO: should we check that the remaining
    -- args are strings?
    output:append(M._append_prefix(left, ...))
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

    local parts = tmpl.parts
    local output = vec()

    inherit.pushindex(tmpl.fenv, env or {})

    for i, part in ipairs(parts) do
      local typ, data = part()
      if typ == M.STR then
        if tmpl:showing() then
          check(M._insert(output, nil, tup.sel(2, part())))
        end
      elseif typ == M.FN then
        local res = tup(data())
        if not M._should_insert(res()) then
          local lpat = "\n[^%S\n]*$"
          local rpat = "^[^%S\n]*\n[^%S\n]*"
          local left = parts:get(i - 1) or tup()
          local right = parts:get(i + 1) or tup()
          local ltyp, ldata = left()
          local rtyp, rdata = right()
          local lmatch = ltyp == M.STR and ldata and ldata:match(lpat)
          local rmatch = rtyp == M.STR and rdata and rdata:match(rpat)
          if lmatch and rmatch then
            parts:set(i - 1, (tup(M.STR, (ldata:gsub(lpat, "")))))
            parts:set(i + 1, (tup(M.STR, (rdata:gsub(rpat, "")))))
          end
        end
        if tmpl:showing() then
          check(M._insert(output, parts:get(i - 1) or tup(), res()))
        end
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

return setmetatable(M, M.MT)
