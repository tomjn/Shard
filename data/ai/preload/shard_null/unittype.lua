ShardUnitType = class(function(a, id)
	a.id = id
	a.def = UnitDefs[id]
end)

function ShardUnitType:ID()
	return self.id
end
