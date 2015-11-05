
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
	return 0
end


function ShardSpringUnit:CanMove()
	return 0
end


function ShardSpringUnit:CanDeploy()
	return 0
end


function ShardSpringUnit:CanBuild()
	return 0
end


function ShardSpringUnit:IsBeingBuilt()
	return 0
end


function ShardSpringUnit:CanAssistBuilding(IUnit* unit) -- the unit that is under construction to help with
	return 0
end


function ShardSpringUnit:CanMoveWhenDeployed()
	return 0
end


function ShardSpringUnit:CanFireWhenDeployed()
	return 0
end


function ShardSpringUnit:CanBuildWhenDeployed()
	return 0
end


function ShardSpringUnit:CanBuildWhenNotDeployed()
	return 0
end


function ShardSpringUnit:Stop()
	return 0
end


function ShardSpringUnit:Move(Position p)
	return 0
end


function ShardSpringUnit:MoveAndFire(Position p)
	return 0
end


function ShardSpringUnit:Build(IUnitType* t)
	return 0
end


function ShardSpringUnit:Build(std::string typeName)
	return 0
end


function ShardSpringUnit:Build(std::string typeName, Position p)
	return 0
end


function ShardSpringUnit:Build(IUnitType* t, Position p)
	return 0
end


function ShardSpringUnit:AreaReclaim(Position p, double radius)
	return 0
end


function ShardSpringUnit:Reclaim(IMapFeature* mapFeature)
	return 0
end


function ShardSpringUnit:Reclaim(IUnit* unit)
	return 0
end


function ShardSpringUnit:Attack(IUnit* unit)
	return 0
end


function ShardSpringUnit:Repair(IUnit* unit)
	return 0
end


function ShardSpringUnit:MorphInto(IUnitType* t)
	return 0
end


function ShardSpringUnit:GetPosition()
	return 0
end


function ShardSpringUnit:GetHealth()
	return 0
end


function ShardSpringUnit:GetMaxHealth()
	return 0
end


function ShardSpringUnit:WeaponCount()
	return 0
end


function ShardSpringUnit:MaxWeaponsRange()
	return 0
end


function ShardSpringUnit:CanBuild(IUnitType* t)
	return 0
end


function ShardSpringUnit:GetResourceUsage(int idx)
	return 0
end


function ShardSpringUnit:ExecuteCustomCommand( int cmdId, std::vector<float> params_list, short options = 0, int timeOut = INT_MAX )
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