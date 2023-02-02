local co = require("santoku.co")

local function tuple ()
  local co = co()
  local function helper (...)
    co.yield(...)
    return helper(co.yield(...))
  end
  local cor = coroutine.create(helper)
  return function (...)
    return select(2, co.resume(cor, ...))
  end
end

-- This is absurd
return function (...)
  local active = tuple()
  local inactive = tuple()
  active(...)
  return {
    -- Stores a value, returns the stored value
    set = function (...)
      inactive(active())
      active(...)
      return inactive()
    end,
    -- Gets the stored value
    get = function (i)
      active, inactive = inactive, active
      return select(i or 1, active(inactive()))
    end
  }
end
