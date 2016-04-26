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

function Shard:shardify_unit( unit )
	shardunit = ShardSpringUnit( unit )
	shardunit:Init( unit )
	return shardunit
end

function Shard:shardify_unittype( unittype )
	shardunittype = ShardSpringUnitType( unit )
	shardunittype:Init( unittype )
	return shardunittype
end

function Shard:GetUnit(unitID)
	if not self.unitsByID[unitID] then
		local unit = ShardSpringUnit()
		unit:Init(unitID)
		self.unitsByID[unitID] = unit
	end
	return self.unitsByID[unitID]
end

return Shard