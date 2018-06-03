
ShardUnitType = class(function(a, id)
	a.id = id
	a.def = UnitDefs[id]
end)

function ShardUnitType:ID()
	return self.id
end

function ShardUnitType:Name()
	return self.def.name
end

function ShardUnitType:Source()
	return self.def
end

function ShardUnitType:CanMove()
	return self.def.canMove
end

function ShardUnitType:CanDeploy()
	-- what does deploy mean for Spring?
	return false
end

function ShardUnitType:CanMorph()
	-- what does deploy mean for Spring?
	return false
end

function ShardUnitType:IsFactory()
	-- what does deploy mean for Spring?
	return self.def.isFactory
end

function ShardUnitType:CanBuild(type)
	if not type then
		return self.def.buildOptions and #self.def.buildOptions > 0
	end
	-- Spring.Echo(self.def.name, "can build?", type, type:Name())
	if not self.canBuildType then
		self.canBuildType = {}
		-- Spring.Echo(self.def.name, "build options", self.def.buildOptions)
		for _, defID in pairs(self.def.buildOptions) do
			self.canBuildType[defID] = true
		end
	end
	return self.canBuildType[type:ID()]
end

function ShardUnitType:WeaponCount()
	return #self.def.weapons -- test this. not sure the weapons table will give its length by the # operator
end

function ShardUnitType:Extractor()
	return self.def.extractsMetal > 0
end

function ShardUnitType:ExtractorEfficiency()
	return self.def.extractsMetal
end


function ShardUnitType:CanAttack()
	return self.def.canAttack
end

function ShardUnitType:CanCloak()
	return self.def.canCloak
end

function ShardUnitType:CanAttackMove()
	return self:CanFight()
end

function ShardUnitType:CanFight()
	return self.def.canFight
end

function ShardUnitType:CanPatrol()
	return self.def.canPatrol
end

function ShardUnitType:CanGuard()
	return self.def.canGuard
end

function ShardUnitType:CanCloak()
	return self.def.canCloak
end

function ShardUnitType:CanSelfDestruct()
	return self.def.canSelfDestruct
end

function ShardUnitType:CanCloak()
	return self.def.canCloak
end

function ShardUnitType:CanRestore()
	return self.def.canRestore
end

function ShardUnitType:CanRepair()
	return self.def.canCloak
end

function ShardUnitType:CanReclaim()
	return self.def.canReclaim
end

function ShardUnitType:CanResurrect()
	return self.def.canResurrect
end

function ShardUnitType:CanCapture()
	return self.def.canCloak
end

function ShardUnitType:CanAssist()
	return self.def.canAssist
end

function ShardUnitType:CanBeAssisted()
	return self.def.canBeAssisted
end

function ShardUnitType:CanSelfRepair()
	return self.def.canSelfRepair
end

function ShardUnitType:IsAirbase()
	return self.def.isAirbase
end

function ShardUnitType:CanHover()
	return self.def.canHover
end

function ShardUnitType:CanFly()
	return self.def.canFly
end

function ShardUnitType:CanSubmerge()
	return self.def.canSubmerge
end

function ShardUnitType:CanBeTransported()
	return not self.def.cantBeTransported
end

function ShardUnitType:CanKamikaze()
	return self.def.canKamikaze
end

function ShardUnitType:isFeatureOnBuilt()
	return self.def.isFeature
end

function ShardUnitType:TargetingPriority()
	return self.def.power -- buildCostMetal + (buildCostEnergy / 60.0) in spring engine
end

function ShardUnitType:BuildOptionsByName()
	return self.def.buildOptions
end
