
ShardSpringUnitType = class(function(a)
   --
end)


function ShardSpringUnitType:Init( id )
	self.id = id
end

function shardify_unittype( unittype )
	shardunittype = ShardSpringUnitType( unit )
	shardunit:Init( unittype )
	return shardunittype
end