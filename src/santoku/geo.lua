local M = {}

M.distance = function (one, two)
  local a = two.x - one.x
  local b = two.y - one.y
  return math.sqrt(a^2 + b^2)
end

-- Generalized perspective projection of 'point'
-- with P=-1, resulting in stereographic
-- projection centered on 'origin'
M.earth_stereo = function (point, origin)
  local p = -1 -- Stereographic perspective
  local R = 3671 -- Earth's radius in kilometers
  local lat1, lon1 = math.rad(origin.lat), math.rad(origin.lon)
  local lat2, lon2 = math.rad(point.lat), math.rad(point.lon)
  local cosc2 = math.sin(lat1) * math.sin(lat2) + math.cos(lat1) * math.cos(lat2) * math.cos(lon2 - lon1)
  local k2 = (p - 1) / (p - cosc2)
  return {
    x = R * k2 * math.cos(lat2) * math.sin(lon2 - lon1),
    y = R * k2 * (math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1))
  }
end

-- In kilometers
M.earth_distance = function (one, two)
  local earth_radius = 6371
  local d_lat = math.rad(two.lat - one.lat)
  local d_lon = math.rad(two.lon - one.lon)
  local lat1 = math.rad(one.lat)
  local lat2 = math.rad(two.lat)
  local a = math.sin(d_lat / 2) * math.sin(d_lat / 2) +
            math.sin(d_lon / 2) * math.sin(d_lon / 2) * math.cos(lat1) * math.cos(lat2)
  local c = 2 * math.atan(math.sqrt(a), math.sqrt(1 - a))
  return earth_radius * c
end

M.rotate = function (point, origin, angle)
  angle = math.rad(360 - angle)
  return {
    x = origin.x + math.cos(angle) * (point.x - origin.x) - math.sin(angle) * (point.y - origin.y),
    y = origin.y + math.sin(angle) * (point.x - origin.x) + math.cos(angle) * (point.y - origin.y)
  }
end

M.angle = function (one, two)
  if one.x == two.x and one.y == two.y then
    return 0
  end
  local theta = math.atan(two.x - one.x, two.y - one.y)
  return (math.deg(theta) + 360) % 360
end

M.bearing = function (one, two)
  local dLon = two.lon - one.lon
  local y = math.sin(dLon) * math.cos(two.lat)
  local x = math.cos(one.lat) * math.sin(two.lat) - math.sin(one.lat)
          * math.cos(two.lat) * math.cos(dLon)
  return 360 - (math.deg(math.atan(y, x)) + 360) % 360
end

return M
