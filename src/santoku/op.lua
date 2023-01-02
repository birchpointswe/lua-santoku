local M = {}

M.eq = function (a, b)
  return a == b
end

M.neq = function (a, b)
  return a ~= b
end

M["and"] = function (a, b)
  return a and b
end

M["or"] = function (a, b)
  return a or b
end

M.lt = function (a, b)
  return a < b
end

M.gt = function (a, b)
  return a > b
end

M.lte = function (a, b)
  return a <= b
end

M.gte = function (a, b)
  return a >= b
end

M.add = function (a, b)
  return a + b
end

M.sub = function (a, b)
  return a - b
end

M.mul = function (a, b)
  return a * b
end

M.div = function (a, b)
  return a / b
end

M.mod = function (a, b)
  return a % b
end

M["not"] = function (a)
  return not a
end

M.neg = function (a)
  return -a
end

M.exp = function (a, b)
  return a ^ b
end

M.len = function (a)
  return #a
end

M.cat = function (a, b)
  return a .. b
end

return M
