require "common"


local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("RunFromAttackBehaviour: " .. inStr)
	end
end

RunFromAttackBehaviour = class(Behaviour)

function RunFromAttackBehaviour:Init()
	self.active = false
	self.underfire = false
	self.lastAttackedFrame = game:Frame()
	-- this is where we will retreat
	self.initialLocation = self.unit:Internal():GetPosition()
	self.name = self.unit:Internal():Name()
	self.mobile = not unitTable[self.name].isBuilding
	EchoDebug("RunFromAttackBehaviour: added to unit "..self.name)
end

function RunFromAttackBehaviour:UnitIdle(unit)
	if unit:Internal():ID() == self.unit:Internal():ID() then
		if self:IsActive() then
			self.underfire = false
			self.unit:ElectBehaviour()
		end
	end
end

function RunFromAttackBehaviour:Update()
	local f = game:Frame()

	-- timeout on underfire condition
	if self.underfire then
		if f > self.lastAttackedFrame + 300 then
			self.underfire = false
		end
	else
		if f % 30 == 0 then
			-- run away preemptively from positions within range of enemy weapons, and notify defenders that the unit is in danger
			local unit = self.unit:Internal()
			local safe
			if commanderList[self.name] then
				safe = ai.targethandler:IsSafePosition(unit:GetPosition(), unit, 0.2)
			else
				safe = ai.targethandler:IsSafePosition(unit:GetPosition(), unit, 2)
			end
			if safe then
				self.underfire = false
				self.unit:ElectBehaviour()
			else
				self.underfire = true
				self.lastAttackedFrame = game:Frame()
				ai.defendhandler:Danger(unit)
				self.unit:ElectBehaviour()
			end
		end
	end
end

function RunFromAttackBehaviour:Activate()
	EchoDebug("RunFromAttackBehaviour: activated on unit "..self.name)

	-- can we move at all?
	if self.mobile then
		-- run to the most defended base location
		local salvation = ai.turtlehandler:MostTurtled(self.unit:Internal())
		if salvation == nil then
			-- if no turtle, find the nearest combat unit
			salvation = self:NearestCombat()
		end
		if salvation == nil then
			-- if none found, just go to where we were built
			salvation = self.initialLocation
		end
		self.unit:Internal():Move(RandomAway(salvation,150))

		self.active = true
		EchoDebug("RunFromAttackBehaviour: unit ".. self.name .." runs away from danger")
	end
end

function RunFromAttackBehaviour:NearestCombat()
	local best
	local ownUnits = game:GetFriendlies()
	local fleeing = self.unit:Internal()
	local fn = fleeing:Name()
	local fid = fleeing:ID()
	local fpos = fleeing:GetPosition()
	local bestDistance = 10000
	for i,unit in pairs(ownUnits) do
		local un = unit:Name()
		if unit:ID() ~= fid and un ~= "corcom" and un ~= "armcom" and not ai.defendhandler:IsDefendingMe(unit, fleeing) then
			if unitTable[un].isWeapon and (battleList[un] or breakthroughList[un]) and unitTable[un].metalCost > unitTable[fn].metalCost * 1.5 then
				local upos = unit:GetPosition()
				if ai.targethandler:IsSafePosition(upos, fleeing) and unit:GetHealth() > unit:GetMaxHealth() * 0.9 and ai.maphandler:UnitCanGetToUnit(fleeing, unit) and not unit:IsBeingBuilt() then
					local dist = Distance(fpos, upos) - unitTable[un].metalCost
					if dist < bestDistance then
						bestDistance = dist
						best = upos
					end
				end
			end
		end
	end
	return best
end

function RunFromAttackBehaviour:Deactivate()
	EchoDebug("RunFromAttackBehaviour: deactivated on unit "..self.name)
	self.active = false
	self.underfire = false
end

function RunFromAttackBehaviour:Priority()
	if self.underfire and self.mobile then
		return 110
	else
		return 0
	end
end

function RunFromAttackBehaviour:UnitDamaged(unit,attacker)
	if unit:Internal():ID() == self.unit:Internal():ID() then
		if not self.underfire then
			self.underfire = true
			self.lastAttackedFrame = game:Frame()
			ai.defendhandler:Danger(unit:Internal())
			self.unit:ElectBehaviour()
		end
	end
end

