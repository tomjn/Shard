shard_include( "attackers" )

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
end

function AttackerBehaviour:UnitBuilt(unit)
	if unit.engineID == self.unit.engineID then
		self.attacking = false
		ai.attackhandler:AddRecruit(self)
	end
end


function AttackerBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		ai.attackhandler:RemoveRecruit(self)
	end
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
		self.unit:Internal():MoveAndFire(self.target)
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
		ai.attackhandler:AddRecruit(self)
	end
end


function AttackerBehaviour:OwnerDied()
	ai.attackhandler:RemoveRecruit(self)
	self.attacking = nil
	self.active = nil
	self.unit = nil
end