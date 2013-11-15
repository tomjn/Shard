require "unitlists"
require "unittable"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("ScoutBehaviour: " .. inStr)
	end
end

function IsScout(unit)
	for i,name in ipairs(scoutList) do
		if name == unit:Internal():Name() then
			return true
		end
	end
	return false
end

ScoutBehaviour = class(Behaviour)

function ScoutBehaviour:Init()
	self.evading = false
	self.active = false
	local mtype, network = ai.maphandler:MobilityOfUnit(self.unit:Internal())
	self.mtype = mtype
	self.name = self.unit:Internal():Name()
end

function ScoutBehaviour:UnitBuilt(unit)

end

function ScoutBehaviour:UnitIdle(unit)
	if unit.engineID == self.unit.engineID then
		if self.active then
			if self.target then
				self.unit:Internal():Move(self.target)
			else
				-- keep scout planes from landing
				if self.mtype == "air" then
					self.unit:Internal():Move(RandomAway(unit:Internal():GetPosition(), 500))
				end
			end
		end
		-- self.unit:ElectBehaviour()
	end
end

function ScoutBehaviour:Priority()
	return 50
end

function ScoutBehaviour:Activate()
	EchoDebug("activated on " .. self.name)
	self.active = true
end

function ScoutBehaviour:Deactivate()
	EchoDebug("deactivated on " .. self.name)
	self.active = false
	self.target = nil
	self.evading = false
end


function ScoutBehaviour:Update()
	local f = game:Frame()
	if math.mod(f,28) == 0 then
		if self.active then
			local unit = self.unit:Internal()
			-- reset target if it's in sight
			if self.target ~= nil then
				local los = ai.scouthandler:ScoutLos(self, self.target)
				EchoDebug("target los: " .. los)
				if los == 2 or los == 3 then
					self.target = nil
				end
			end
			-- attack small targets along the way if the scout is armed
			local attackTarget
			if unit:WeaponCount() > 0 then
				if ai.targethandler:IsSafePosition(unit:GetPosition(), unit, 1) then
					attackTarget = ai.targethandler:NearbyVulnerable(unit)
				end
			end
			if attackTarget then
				unit:Attack(attackTarget)
			elseif self.target ~= nil then
				-- evade enemies along the way if possible
				local newPos, arrived = ai.targethandler:BestAdjacentPosition(unit, self.target)
				if newPos then
					unit:Move(newPos)
					self.evading = true
				elseif arrived then
					-- if we're at the target, find a new target
					self.target = nil
					self.evading = false
				elseif self.evading then
					-- return to course to target after evading
					unit:Move(self.target)
					self.evading = false
				end
			end
			-- find new scout spot if none and not attacking
			if self.target == nil and attackTarget == nil then
				local topos = ai.scouthandler:ClosestSpot(self) -- first look for closest metal/geo spot that hasn't been seen recently
				if topos ~= nil then
					EchoDebug("scouting spot at " .. topos.x .. "," .. topos.z)
					local keepYourDistance = unitTable[self.name].losRadius * 16 -- don't move directly onto the spot
					self.target = RandomAway(topos, keepYourDistance)
					unit:Move(self.target)
				else
					EchoDebug("nothing to scout!")
				end
			end
			-- self.unit:ElectBehaviour()
		end
	end
	
	-- keep air units circling
	if math.mod(f, 59) == 0 then
		if self.target then
			local unit = self.unit:Internal()
			if self.mtype == "air" then
				local upos = unit:GetPosition()
				local dist = distance(upos, self.target)
				if dist < unitTable[self.name].losRadius * 48 then
					unit:Move(RandomAway(self.target, 100))
				end
			end
		end
	end
end