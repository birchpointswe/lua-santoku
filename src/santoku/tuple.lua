local function tuple (n, a, ...)
  if n == 0 then
    return function (...) 
      return ... 
    end, 0
  else 
    local rest = tuple(n - 1, ...)
    return function (...)
      return a, rest(...)
    end, n
  end
end

return function (...)
  return tuple(select("#", ...), ...)
end
