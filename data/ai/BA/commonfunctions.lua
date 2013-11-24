sqrt = math.sqrt
random = math.random
pi = math.pi
cos = math.cos
sin = math.sin

function RandomAway(pos, dist, opposite, angle)
	if angle == nil then angle = random() * 2 * pi end
	local away = api.Position()
	away.x = pos.x + dist * math.sin(angle)
	away.z = pos.z + dist * math.cos(angle)
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
		angle = (2 * pi) - angle
		return away, RandomAway(pos, dist, false, angle)
	else
		return away
	end

	--[[
	local xdelta = math.random(0, dist*2) - dist
	local zmult = math.random(0,1) == 1 and 1 or -1
	local zdelta = (dist - math.abs(xdelta)) * zmult
	local away = api.Position()
	away.x = pos.x + xdelta
	away.z = pos.z + zdelta
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
		local oppositeAway = api.Position()
		oppositeAway.x = pos.x - xdelta
		oppositeAway.z = pos.z - zdelta
		oppositeAway.y = pos.y
		if oppositeAway.x < 1 then
			oppositeAway.x = 1
		elseif oppositeAway.x > ai.maxElmosX - 1 then
			oppositeAway.x = ai.maxElmosX - 1
		end
		if oppositeAway.z < 1 then
			oppositeAway.z = 1
		elseif oppositeAway.z > ai.maxElmosZ - 1 then
			oppositeAway.z = ai.maxElmosZ - 1
		end
		return away, oppositeAway
	else
		return away
	end
	]]--
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