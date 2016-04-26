
ShardSpringUnitType = class(function(a)
   --
end)


function ShardSpringUnitType:Init( id )
	self.id = id
	self.def = UnitDefs[id]
end

function ShardSpringUnitType:ID()
	return self.id
end

function ShardSpringUnitType:CanMove()
	return self.def.canMove
end

function ShardSpringUnitType:CanDeploy()
	-- what does deploy mean for Spring?
	return false
end

function ShardSpringUnitType:CanBuild(type)
	if not type then return self.def.isBuilder end
	if not self.canBuildType then
		self.canBuildType = {}
		for _, defID in pairs(self.def.buildOptions) do
			local shardType = Shard.shardify_unittype(defID)
			self.canBuildType[shardType] = true
		end
	end
	return self.canBuildType[type]
end

function ShardSpringUnitType:WeaponCount()
	return #self.def.weapons -- test this. not sure the weapons table will give its length by the # operator
end