local M = {}

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
  M.unimplemented("interp")
end

-- TODO
-- Indent or de-dent strings
--   opts.char = indent char, default ' '
--   opts.level = indent level, default auto
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
