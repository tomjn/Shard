local Shard = {}

Shard.resourceIds = { "metal", "energy" }
Shard.resourceKeyAliases = {
	currentLevel = "reserves",
	storage = "capacity",
	expense = "usage",
}

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

return Shard