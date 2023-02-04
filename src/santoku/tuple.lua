local function tuple (n, a, ...)
  if n == 0 then
    return function (k, ...)
      return k(...)
    end, 0
  else
    local rest = tuple(n - 1, ...)
    return function (k, ...)
      return rest(function (...)
        return k(a, ...)
      end, ...)
    end, n
  end
end

return function (...)
  return tuple(select("#", ...), ...)
end
