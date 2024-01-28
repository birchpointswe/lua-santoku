-- TODO: Convert to use santoku.matrix

local compat = require("santoku.compat")

local sqrt = math.sqrt
local rad = math.rad
local atan = compat.atan
local sin = math.sin
local cos = math.cos
local deg = math.deg

local function distance (one, two)
  local a = two.x - one.x
  local b = two.y - one.y
  return sqrt(a^2 + b^2)
end

-- Generalized perspective projection of 'point'
-- with P=-1, resulting in stereographic
-- projection centered on 'origin'
local function earth_stereo (point, origin)
  local p = -1 -- Stereographic perspective
  local R = 3671 -- Earth's radius in kilometers
  local lat1, lon1 = rad(origin.lat), rad(origin.lon)
  local lat2, lon2 = rad(point.lat), rad(point.lon)
  local cosc2 = sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(lon2 - lon1)
  local k2 = (p - 1) / (p - cosc2)
  return {
    x = R * k2 * cos(lat2) * sin(lon2 - lon1),
    y = R * k2 * (cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1))
  }
end

-- In kilometers
local function earth_distance (one, two)
  local earth_radius = 6371
  local d_lat = rad(two.lat - one.lat)
  local d_lon = rad(two.lon - one.lon)
  local lat1 = rad(one.lat)
  local lat2 = rad(two.lat)
  local a = sin(d_lat / 2) * sin(d_lat / 2) +
            sin(d_lon / 2) * sin(d_lon / 2) * cos(lat1) * cos(lat2)
  local c = 2 * compat.atan(sqrt(a), sqrt(1 - a))
  return earth_radius * c
end

local function rotate (point, origin, angle)
  angle = rad(360 - angle)
  return {
    x = origin.x + cos(angle) * (point.x - origin.x) - sin(angle) * (point.y - origin.y),
    y = origin.y + sin(angle) * (point.x - origin.x) + cos(angle) * (point.y - origin.y)
  }
end

local function angle (one, two)
  if one.x == two.x and one.y == two.y then
    return 0
  end
  local theta = atan(two.x - one.x, two.y - one.y)
  return (deg(theta) + 360) % 360
end

local function bearing (one, two)
  local dLon = two.lon - one.lon
  local y = sin(dLon) * cos(two.lat)
  local x = cos(one.lat) * sin(two.lat) - sin(one.lat)
          * cos(two.lat) * cos(dLon)
  return 360 - (deg(atan(y, x)) + 360) % 360
end

return {
  distance = distance,
  earth_stereo = earth_stereo,
  earth_distance = earth_distance,
  rotate = rotate,
  angle = angle,
  bearing = bearing,
}
