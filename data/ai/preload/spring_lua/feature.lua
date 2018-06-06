
ShardSpringFeature = class(function(a, id)
	a.id = id
	a.defID = Spring.GetFeatureDefID(id)
	a.def = FeatureDefs[a.defID]
	a.name = a.def.name
end)

function ShardSpringFeature:ID()
	return self.id
end

function ShardSpringFeature:Name()
	return self.name
end

function ShardSpringFeature:GetPosition()
	local x, y, z = Spring.GetFeaturePosition(self.id)
	return {x=x, y=y, z=z}
end