local function tuple (n, a, ...)
  if n == 0 then
    return function () end
  else 
    local rest = tuple(n - 1, ...)
    return function (n)
      return select(n or 1, a, rest())
    end
  end
end

return function (...)
  return tuple(select("#", ...), ...)
end
