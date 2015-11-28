
ShardSpringUnit = class(function(a)
   --
end)


function ShardSpringUnit:Init( id )
	self.id = id
end

function ShardSpringUnit:ID()
	return self.id
end

function ShardSpringUnit:Team()
	return 0
end


function ShardSpringUnit:Name()
	return 0
end


function ShardSpringUnit:IsAlive()
	return true
end


function ShardSpringUnit:IsCloaked()
	return false
end


function ShardSpringUnit:Forget()
	return 0
end


function ShardSpringUnit:Forgotten()
	return false
end


function ShardSpringUnit:Type()
	local name = self:Name()
	return game:GetTypeByName( name )
end


function ShardSpringUnit:CanMove()
	return false
end


function ShardSpringUnit:CanDeploy()
	return false
end


function ShardSpringUnit:CanBuild()
	return false
end


function ShardSpringUnit:IsBeingBuilt()
	return false
end


function ShardSpringUnit:CanAssistBuilding( unit )-- IUnit* unit) -- the unit that is under construction to help with
	return false
end


function ShardSpringUnit:CanMoveWhenDeployed()
	return false
end


function ShardSpringUnit:CanFireWhenDeployed()
	return false
end


function ShardSpringUnit:CanBuildWhenDeployed()
	return false
end


function ShardSpringUnit:CanBuildWhenNotDeployed()
	return false
end


function ShardSpringUnit:Stop()
	Spring.GiveOrderToUnit( self.id, CMD.STOP )
	return true
end


function ShardSpringUnit:Move(p)
	Spring.GiveOrderToUnit( self.id, CMD.MOVE, { p.x, p.y, p.z } )
	return true
end


function ShardSpringUnit:MoveAndFire(p)
	Spring.GiveOrderToUnit( self.id, CMD.FIGHT, { p.x, p.y, p.z } )
	return true
end


function ShardSpringUnit:Build(t) -- IUnitType*
	return false
end


function ShardSpringUnit:Build(typeName) -- std::string
	return false
end


function ShardSpringUnit:Build(typeName, p) -- std::string , Position
	return false
end


function ShardSpringUnit:Build( type, position ) -- IUnitType* t, Position p)
	return false
end


function ShardSpringUnit:AreaReclaim( position, radius )--Position p, double radius)
	return false
end


function ShardSpringUnit:Reclaim( feature )--IMapFeature* mapFeature)
	return false
end


function ShardSpringUnit:Reclaim( unit )
	return false
end


function ShardSpringUnit:Attack( unit )
	return false
end


function ShardSpringUnit:Repair( unit )
	return false
end


function ShardSpringUnit:MorphInto( type )
	return false
end


function ShardSpringUnit:GetPosition()
	local bpx, bpy, bpz = Spring.GetUnitPosition(self.id)
	return {
		x=bpx,
		y=bpy,
		z=bpz
	}
end


function ShardSpringUnit:GetHealth()
	local health, maxHealth, paralyzeDamage, captureProgress, buildProgress = Spring.GetUnitHealth( self.id )
	return health
end


function ShardSpringUnit:GetMaxHealth()
	local health, maxHealth, paralyzeDamage, captureProgress, buildProgress = Spring.GetUnitHealth( self.id )
	return maxHealth
end


function ShardSpringUnit:WeaponCount()
	return 0
end


function ShardSpringUnit:MaxWeaponsRange()
	return Spring.GetUnitMaxRange(self.id)
end


function ShardSpringUnit:CanBuild( type )
	return false
end


function ShardSpringUnit:GetResourceUsage( idx )
	return 0
end


function ShardSpringUnit:ExecuteCustomCommand(  cmdId, params_list, options, timeOut )
	return 0
end
--[[
IUnit/ engine unit objects
	int ID()
	int Team()
	std::string Name()

	bool IsAlive()

	bool IsCloaked()

	void Forget() // makes the interface forget about this unit and cleanup
	bool Forgotten() // for interface/debugging use

	IUnitType* Type()

	bool CanMove()
	bool CanDeploy()
	bool CanBuild()
	bool IsBeingBuilt()

	bool CanAssistBuilding(IUnit* unit)

	bool CanMoveWhenDeployed()
	bool CanFireWhenDeployed()
	bool CanBuildWhenDeployed()
	bool CanBuildWhenNotDeployed()

	void Stop()
	void Move(Position p)
	void MoveAndFire(Position p)

	bool Build(IUnitType* t)
	bool Build(std::string typeName)
	bool Build(std::string typeName, Position p)
	bool Build(IUnitType* t, Position p)

	bool AreaReclaim(Position p, double radius)
	bool Reclaim(IMapFeature* mapFeature)
	bool Reclaim(IUnit* unit)
	bool Attack(IUnit* unit)
	bool Repair(IUnit* unit)
	bool MorphInto(IUnitType* t)

	Position GetPosition()
	float GetHealth()
	float GetMaxHealth()

	int WeaponCount()
	float MaxWeaponsRange()

	bool CanBuild(IUnitType* t)

	SResourceTransfer GetResourceUsage(int idx)

	void ExecuteCustomCommand(int cmdId, std::vector<float> params_list, short options = 0, int timeOut = INT_MAX)
--]]


function shardify_unit( unit )
	shardunit = ShardSpringUnit( unit )
	shardunit:Init( unit )
	return shardunit
end