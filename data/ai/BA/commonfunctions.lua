sqrt = math.sqrt
random = math.random
pi = math.pi
halfPi = pi / 2
twicePi = pi * 2
cos = math.cos
sin = math.sin
atan2 = math.atan2

function RandomAway(pos, dist, opposite, angle)
	if angle == nil then angle = random() * twicePi end
	local away = api.Position()
	away.x = pos.x + dist * cos(angle)
	away.z = pos.z - dist * sin(angle)
	away.y = pos.y
	if away.x < 1 then
		away.x = 1
	elseif away.x > ai.maxElmosX - 1 then
		away.x = ai.maxElmosX - 1
	end
	if away.z < 1 then
		away.z = 1
	elseif away.z > ai.maxElmosZ - 1 then
		away.z = ai.maxElmosZ - 1
	end
	if opposite then
		angle = twicePi - angle
		return away, RandomAway(pos, dist, false, angle)
	else
		return away
	end
end

function Distance(pos1,pos2)
	local xd = pos1.x-pos2.x
	local yd = pos1.z-pos2.z
	local dist = sqrt(xd*xd + yd*yd)
	return dist
end

function ManhattanDistance(pos1,pos2)
	local xd = math.abs(pos1.x-pos2.x)
	local yd = math.abs(pos1.z-pos2.z)
	local dist = xd + yd
	return dist
end

function PositionsWithinSquare(pos1, pos2, dist)
	local halfDist = dist / 2
	return pos1.x >= pos2.x - halfDist and pos1.x <= pos2.x + halfDist and pos1.z >= pos2.z - halfDist and pos1.z <= pos2.z + halfDist
end

function PositionWithinRect(position, rect)
	local x1, z1, x2, z2
	if rect.x1 > rect.x2 then
		x1 = rect.x2
		x2 = rect.x1
	else
		x1 = rect.x1
		x2 = rect.x2
	end
	if rect.z1 > rect.z2 then
		z1 = rect.z2
		z2 = rect.z1
	else
		z1 = rect.z1
		z2 = rect.z2
	end
	return position.x >= x1 and position.x <= x2 and position.z >= z1 and position.z <= z2
end

function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end