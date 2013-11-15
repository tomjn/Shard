require "unitlists"
require "unittable"

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
		if f > self.lastAttackedFrame + 600 then
			self.underfire = false
		end
	else
		if f % 30 == 0 then
			-- run away preemptively from positions within range of enemy weapons, and notify defenders that the unit is in danger
			local unit = self.unit:Internal()
			if ai.targethandler:IsSafePosition(unit:GetPosition(), unit) then
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
	EchoDebug("RunFromAttackBehaviour: active on unit "..self.name)

	-- can we move at all?
	if self.unit:Internal():CanMove() then
		-- try to find a friendly weapon and run there
		local ownUnits = game:GetFriendlies()
		local salvation = self.initialLocation -- fall back to where the fleeing unit was built if no saviour can be found
		local fleeing = self.unit:Internal()
		local fn = fleeing:Name()
		local fid = fleeing:ID()
		local fpos = fleeing:GetPosition()
		local bestDistance = 10000
		for i,unit in pairs(ownUnits) do
			local un = unit:Name()
			if unit:ID() ~= fid and un ~= "corcom" and un ~= "armcom" and not ai.defendhandler:IsDefendingMe(unit, fleeing) then
				if unitTable[un].isWeapon and (unitTable[un].isBuilding or unitTable[un].metalCost > unitTable[fn].metalCost) then
					local upos = unit:GetPosition()
					if ai.targethandler:IsSafePosition(upos, fleeing) and unit:GetHealth() > unit:GetMaxHealth() * 0.75 and ai.maphandler:UnitCanGetToUnit(fleeing, unit) and not unit:IsBeingBuilt() then
						local dist = distance(fpos, upos) - unitTable[un].metalCost
						if dist < bestDistance then
							bestDistance = dist
							salvation = upos
						end
					end
				end
			end
		end
		self.unit:Internal():Move(RandomAway(salvation,100))

		self.active = true
		EchoDebug("RunFromAttackBehaviour: unit ".. self.name .." runs away from danger")
	end
end

function RunFromAttackBehaviour:Deactivate()
	EchoDebug("RunFromAttackBehaviour: deactivated on unit "..self.name)
	self.active = false
	self.underfire = false
end

function RunFromAttackBehaviour:Priority()
	if self.underfire then
		return 110
	end
	return 0
end

function RunFromAttackBehaviour:UnitDamaged(unit,attacker)
	if unit:Internal():ID() == self.unit:Internal():ID() then
		if not self:IsActive() then
			self.underfire = true
			self.lastAttackedFrame = game:Frame()
			ai.defendhandler:Danger(unit:Internal())
			self.unit:ElectBehaviour()
		end
	end
end

