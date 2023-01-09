local gen = require("santoku.gen")

-- TODO: Consider using table instead of gen for
-- these functions since they're usually strict
-- TODO: Provide a wrapper function so that
-- strings can be used in an oop style.
--   - setmetatable({ s = s }, { ... })
--   - Use inherit so that we can inherit bot
--     this library and "string"

local M = {}

M.matcher = function (pat)
  assert(type(pat) == "string")
  return function (str)
    assert(type(str) == "string")
    return gen.gennil(str:gmatch(pat))
  end
end

M.match = function (str, pat)
  assert(type(str) == "string")
  assert(type(pat) == "string")
  return M.matcher(pat)(str)
end

-- Split a string
--   opts.delim == false: throw out delimiters
--   opts.delim == true: keep delimiters as
--     separate tokens
--   opts.delim == "left": keep delimiters
--     concatenated to the left token
--   opts.delim == "right": keep delimiters
--     concatenated to the right token
--
-- TODO: allow splitting specific number of times from left or
-- right
--   opts.times: default == true
--   opts.times == true: as many as possible from left
--   opts.times == false: as many times as possible from right
--   opts.times > 0: number of times, starting from left
--   opts.times < 0: number of times, starting from right
M.splitter = function (pat, opts)
  opts = opts or {}
  local delim = opts.delim or false
  return function (str)
    return gen.genco(function (co)
      local n = 0
      local ls = 0
      local stop = false
      while not stop do
        local s, e = str:find(pat, n)
        stop = s == nil
        if stop then
          s = #str + 1
        end
        if delim == true then
          co.yield(str:sub(n, s - 1))
          if not stop then
            co.yield(str:sub(s, e))
          end
        elseif delim == "left" then
          co.yield(str:sub(n, e))
        elseif delim == "right" then
          co.yield(str:sub(ls, s - 1))
        else
          co.yield(str:sub(n, s - 1))
        end
        if stop then
          break
        else
          ls = s
          n = e + 1
        end
      end
    end)
  end
end

M.split = function (str, pat, opts)
  return M.splitter(pat, opts)(str)
end

-- Escape strings for use in sub, gsub, etc
M.escape = function (s)
  return (s:gsub("[%(%)%.%%+%-%*%?%[%]%^%$]", "%%%1"))
end

-- Unescape strings for use in sub, gsub, etc
M.unescape = function (s)
  return (s:gsub("%%([%(%)%.%%+%-%*%?%[%]%^%$])", "%1"))
end

M.printf = function (s, ...)
  return io.write(s:format(...))
end

-- TODO
-- Print interpolated
M.printi = function (s, t)
  return print(M.interp(s, t))
end

-- TODO
-- Interpolate strings
--   "Hello %name. %adjective to meet you."
--   "Name: %name. Age: %d:age"
M.interp = function (s, t)
  return table.concat(M.split(s, "%%%w*", {
    delim = true
  }):map(function (s)
    local v = s:match("%%(%w*)")
    if v ~= nil then
      return t[v]
    else
      return s
    end
  end):collect())
end

-- TODO
-- Indent or de-dent strings
--   opts.char = indent char, default ' '
--   opts.level = indent level, default auto
--   opts.dir = indent direction, default "in"
M.indent = function (s, opts)
  M.unimplemented("indent")
end

-- TODO
-- Trim strings
--   opts = string pattern for string.sub, defaults to
--   whitespace
--   opts.begin = same as opts but for begin
--   opts.end = same as opts but for end
M.trim = function (s, opts)
  M.unimplemented("trim")
end

return M
