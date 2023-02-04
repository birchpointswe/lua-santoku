local function tuple (n, a, ...)
  if n == 0 then
    return function (...) return ... end
  else 
    local rest = tuple(n - 1, ...)
    return function (...)
      return a, rest(...)
    end
  end
end

return function (...)
  return tuple(select("#", ...), ...)
end
