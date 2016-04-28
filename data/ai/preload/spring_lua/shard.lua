local Shard = {}

Shard.resourceIds = { "metal", "energy" }
Shard.resourceKeyAliases = {
	currentLevel = "reserves",
	storage = "capacity",
	expense = "usage",
}
Shard.unitsByID = {}
Shard.unittypesByID = {}

function Shard:shardify_resource(luaResource)
	local shardResource = {}
	for key, value in pairs(luaResource) do
		local newKey = self.resourceKeyAliases[key] or key
		shardResource[newKey] = value
	end
	return shardResource
end

function Shard:shardify_unit( unitID )
	if not unitID then return end
	if not self.unitsByID[unitID] then
		local unit = ShardSpringUnit()
		unit:Init(unitID)
		self.unitsByID[unitID] = unit
	end
	return self.unitsByID[unitID]
end

function Shard:unshardify_unit( unitID )
	if not unitID then return end
	self.unitsByID[unitID] = nil
end

function Shard:shardify_unittype( unitDefID )
	if not unitDefID then return end
	if not self.unittypesByID[unitDefID] then
		local unittype = ShardSpringUnitType()
		unittype:Init(unitDefID)
		self.unittypesByID[unitDefID] = unittype
	end
	return self.unittypesByID[unitDefID]
end

function Shard:shardify_damage( damage, weaponDefId, paralyzer )
	local sharddamage = ShardSpringDamage()
	sharddamage:Init(damage, weaponDefId, paralyzer)
	return sharddamage
end

return Shard