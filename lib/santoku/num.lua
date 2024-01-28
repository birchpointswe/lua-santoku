-- TODO: Migrate to santoku.matrix

local modf = math.modf

local function trunc (n, d)
  local i, f = modf(n)
  d = 10^d
  return i + modf(f * d) / d
end

return {
  trunc = trunc
}
