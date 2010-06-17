-- ahoi there!!!
MetalSpotHandler = class(AIBase)

function MetalSpotHandler:Init()
	self.spots = game:GetMetalSpots()
	--[[{}
	spotCount = game:SpotCount()
	for i=0, spotCount-1 do
		p = game:GetSpot(i)
		table.insert(self.spots,p)
	end]]--
end

function distance(pos1,pos2)
	local xd = pos1.x-pos2.x
	local yd = pos1.z-pos2.z
	dist = math.sqrt(xd*xd + yd*yd)
	return dist
end

function MetalSpotHandler:ClosestFreeSpot(unittype,position)
	local pos = nil
	local bestDistance = 10000
	
	spotCount = game:SpotCount()
	for i,v in ipairs(self.spots) do
		local p = v
		local dist = distance(position,p)
		if dist < bestDistance then
			if game:CanBuildHere(unittype,p) then
				bestDistance = dist
				pos = p
			end
		end
	end
	return pos
end
