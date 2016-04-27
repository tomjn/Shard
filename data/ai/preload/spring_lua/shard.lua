local Shard = {}

Shard.resourceIds = { "metal", "energy" }
Shard.resourceKeyAliases = {
	currentLevel = "reserves",
	storage = "capacity",
	expense = "usage",
}
Shard.unitsByID = {}

function Shard:shardify_resource(luaResource)
	local shardResource = {}
	for key, value in pairs(luaResource) do
		local newKey = self.resourceKeyAliases[key] or key
		shardResource[newKey] = value
	end
	return shardResource
end

function Shard:shardify_unit( unitID )
	if not self.unitsByID[unitID] then
		local unit = ShardSpringUnit()
		unit:Init(unitID)
		self.unitsByID[unitID] = unit
	end
	return self.unitsByID[unitID]
end

function Shard:shardify_unittype( unittype )
	local shardunittype = ShardSpringUnitType( unittype )
	shardunittype:Init( unittype )
	return shardunittype
end

function Shard:shardify_damage( damage, weaponDefId, paralyzer )
	local sharddamage = ShardSpringDamage()
	sharddamage:Init(damage, weaponDefId, paralyzer)
	return sharddamage
end

return Shard