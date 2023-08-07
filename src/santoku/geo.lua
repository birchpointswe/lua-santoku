local M = {}

M.distance = function (one, two)
  local a = two.x - one.x
  local b = two.y - one.y
  return math.sqrt(a^2 + b^2)
end

M.earth_distance = function (one, two)
  local earth_radius_km = 6371
  local d_lat = math.rad(two.lat - one.lat)
  local d_lon = math.rad(two.lon - one.lon)
  local lat1 = math.rad(one.lat)
  local lat2 = math.rad(two.lat)
  local a = math.sin(d_lat / 2) * math.sin(d_lat / 2) +
            math.sin(d_lon / 2) * math.sin(d_lon / 2) * math.cos(lat1) * math.cos(lat2)
  local c = 2 * math.atan(math.sqrt(a), math.sqrt(1 - a))
  return earth_radius_km * c
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
  if theta < 0 then
    theta = theta + math.pi * 2
  end
  return math.deg(theta)
end

M.bearing = function (one, two)
  local dLon = two.lon - one.lon
  local y = math.sin(dLon) * math.cos(two.lat)
  local x = math.cos(one.lat) * math.sin(two.lat) - math.sin(one.lat)
          * math.cos(two.lat) * math.cos(dLon)
  return 360 - (math.deg(math.atan(y, x)) + 360) % 360
end

return M
