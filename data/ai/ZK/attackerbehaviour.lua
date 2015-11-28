require "attackers"

function IsAttacker(unit)
	for i,name in ipairs(attackerlist) do
		if name == unit:Internal():Name() then
			return true
		end
	end
	return false
end

AttackerBehaviour = class(Behaviour)

function AttackerBehaviour:Init()
	--game:SendToConsole("attacker!")
	self.dead = false
end

function AttackerBehaviour:UnitBuilt(unit)
	if unit.engineID == self.unit.engineID then
		self:SetInitialState()
		self.attacking = false
		ai.attackhandler:AddRecruit(self)
	end
end


function AttackerBehaviour:UnitDead(unit)
	--
end

function AttackerBehaviour:UnitIdle(unit)
	if unit.engineID == self.unit.engineID then
		self.attacking = false
		ai.attackhandler:AddRecruit(self)
	end
end

function AttackerBehaviour:AttackCell(cell)
	p = api.Position()
	p.x = cell.posx
	p.z = cell.posz
	p.y = 0
	self.target = p
	self.attacking = true
	if self.active then
		local u = self.unit:Internal()
		u:MoveAndFire(self.target)
	else
		self.unit:ElectBehaviour()
	end
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
		self.unit:Internal():MoveAndFire(self.target)
		self.target = nil
	else
		--ai.attackhandler:AddRecruit(self)
	end
end

function AttackerBehaviour:SetInitialState()
	local CMD_FIRE_STATE = 45
	local CMD_MOVE_STATE = 50
	local CMD_RETREAT = 34223
	local thisUnit = self.unit
	if thisUnit then
		local floats = api.vectorFloat()
		floats:push_back(2)
		thisUnit:Internal():ExecuteCustomCommand(CMD_MOVE_STATE, floats)
		thisUnit:Internal():ExecuteCustomCommand(CMD_FIRE_STATE, floats)
		
		local isHeavy = thisUnit:Internal():GetMaxHealth() >= 1250
		if (isHeavy) then
			thisUnit:Internal():ExecuteCustomCommand(CMD_RETREAT, floats)
		end
	end
end

function AttackerBehaviour:OwnerDead()
	ai.attackhandler:RemoveRecruit(self)
	self.attacking = nil
	self.active = nil
	self.unit = nil
end
