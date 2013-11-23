require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("AttackerBehaviour: " .. inStr)
	end
end

local CMD_MOVE_STATE = 50
local MOVESTATE_HOLDPOS = 0
local MOVESTATE_ROAM = 2

function IsAttacker(unit)
	local uname = unit:Internal():Name()
	for i,name in ipairs(attackerlist) do
		if name == uname then
			return true
		end
	end
	return false
end

AttackerBehaviour = class(Behaviour)

function AttackerBehaviour:Init()
	local mtype, network = ai.maphandler:MobilityOfUnit(self.unit:Internal())
	self.mtype = mtype
	self.name = self.unit:Internal():Name()
end

function AttackerBehaviour:UnitBuilt(unit)
	if unit.engineID == self.unit.engineID then
		self.attacking = false
		ai.attackhandler:AddRecruit(self)
	end
end

function AttackerBehaviour:UnitDamaged(unit,attacker)
	if unit.engineID == self.unit.engineID then
		self.damaged = game:Frame()
	end
end

function AttackerBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		-- game:SendToConsole("attacker " .. self.name .. " died")
		ai.attackhandler:NeedMore(self)
		ai.attackhandler:RemoveRecruit(self)
		ai.attackhandler:RemoveMember(self)
	end
end

function AttackerBehaviour:UnitIdle(unit)
	if unit.engineID == self.unit.engineID then
		--[[
		self.attacking = false
		if not ai.attackhandler:IsRecruit(self) and not ai.attackhandler:IsMember(self) then
			ai.attackhandler:AddRecruit(self)
		end
		self.unit:ElectBehaviour()
		]]--
	end
end

function AttackerBehaviour:Attack(pos)
	if self.unit == nil then
		-- wtf
	elseif self.unit:Internal() == nil then
		-- wwttff
	else
		self.target = RandomAway(pos, 75)
		self.attacking = true
		self.congregating = false
		if self.active then
			self.unit:Internal():MoveAndFire(self.target)
		end
		self.unit:ElectBehaviour()
	end
end

function AttackerBehaviour:Congregate(pos)
	local ordered = false
	if self.unit == nil then
		return false
	elseif self.unit:Internal() == nil then
		return false
	else
		local unit = self.unit:Internal()
		self.target = pos
		if ai.maphandler:UnitCanGoHere(unit, pos) then
			self.attacking = true
			self.congregating = true
			if self.active then
				unit:Move(self.target)
			end
			ordered = true
		end
		self.unit:ElectBehaviour()
	end
	return ordered
end

function AttackerBehaviour:Free()
	self.attacking = false
	self.congregating = false
	self.target = nil
	self.unit:ElectBehaviour()
end

function AttackerBehaviour:Priority()
	if not self.attacking then
		return 0
	else
		return 100
	end
end

function AttackerBehaviour:Activate()
	self.active = true
	if self.target then
		if self.congregating then
			self.unit:Internal():Move(self.target)
		else
			self.unit:Internal():MoveAndFire(self.target)
		end
	end
end

function AttackerBehaviour:Deactivate()
	self.active = false
end

function AttackerBehaviour:Update()
	if self.damaged then
		local f = game:Frame()
		if f > self.damaged + 450 then
			self.damaged = nil
		end
	end
end

-- this will issue Hold Pos order to units that need it
function AttackerBehaviour:SetMoveState()
	local thisUnit = self.unit
	if thisUnit then
		local unitName = self.name
		if holdPositionList[unitName] then
			local floats = api.vectorFloat()
			floats:push_back(MOVESTATE_HOLDPOS)
			thisUnit:Internal():ExecuteCustomCommand(CMD_MOVE_STATE, floats)
		end
		if roamList[unitName] then
			local floats = api.vectorFloat()
			floats:push_back(MOVESTATE_ROAM)
			thisUnit:Internal():ExecuteCustomCommand(CMD_MOVE_STATE, floats)
			
		end
	end
end