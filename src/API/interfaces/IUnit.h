#ifndef IUNIT_H
#define IUNIT_H

#include "IUnitType.h"
#include "../Position.h"
#include <climits>

class IUnit {
public:
	virtual ~IUnit(){}
	virtual int ID()=0;
	virtual int Team()=0;
	virtual std::string Name()=0;

	virtual bool IsAlive()=0;

	virtual bool IsCloaked()=0;
	
	virtual IUnitType* Type()=0;

	virtual bool CanMove()=0;
	virtual bool CanDeploy()=0;
	virtual bool CanBuild()=0;
	virtual bool IsBeingBuilt()=0;
	
	virtual bool CanAssistBuilding(IUnit* unit)=0;

	virtual bool CanMoveWhenDeployed()=0;
	virtual bool CanFireWhenDeployed()=0;
	virtual bool CanBuildWhenDeployed()=0;
	virtual bool CanBuildWhenNotDeployed()=0;

	virtual void Wait(int timeout)=0;
	virtual void Stop()=0;
	virtual void Move(Position p)=0;
	virtual void MoveAndFire(Position p)=0;

	virtual bool Build(IUnitType* t)=0;
	virtual bool Build(std::string typeName)=0;
	virtual bool Build(std::string typeName, Position p)=0;
	virtual bool Build(IUnitType* t, Position p)=0;
	virtual bool Build(std::string typeName, Position p, int facing)=0;
	virtual bool Build(IUnitType* t, Position p, int facing)=0;

	virtual bool AreaReclaim(Position p, double radius)=0;
	virtual bool Reclaim(IMapFeature* mapFeature)=0;
	virtual bool Reclaim(IUnit* unit)=0;
	virtual bool Attack(IUnit* unit)=0;
	virtual bool Repair(IUnit* unit)=0;
	virtual bool MorphInto(IUnitType* t)=0;
	
	virtual Position GetPosition()=0;
	virtual float GetHealth()=0;
	virtual float GetMaxHealth()=0;

	virtual int WeaponCount()=0;
	virtual float MaxWeaponsRange()=0;

	virtual bool CanBuild(IUnitType* t)=0;

	virtual SResourceTransfer GetResourceUsage(int idx)=0;

	virtual void ExecuteCustomCommand(int cmdId, std::vector<float> params_list, short options = 0, int timeOut = INT_MAX)=0;

};

#endif
