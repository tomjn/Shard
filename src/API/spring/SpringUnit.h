#pragma once

#include "../interfaces/IMapFeature.h"
#include "../interfaces/IUnit.h"
#include "../interfaces/IGame.h"

class CSpringUnit : public IUnit {
public:
	CSpringUnit(springai::OOAICallback* callback, springai::Unit* u, IGame* game);
	virtual ~CSpringUnit();

	virtual int ID();
	virtual int Team();
	virtual std::string Name();

	virtual void SetDead(bool dead=true);
	virtual bool IsAlive();

	virtual bool IsCloaked();

	virtual void Forget(); // makes the interface forget about this unit and cleanup
	virtual bool Forgotten(); // for interface/debugging use
	
	virtual IUnitType* Type();

	virtual bool CanMove();
	virtual bool CanDeploy();
	virtual bool CanBuild();
	
	virtual bool CanAssistBuilding(IUnit* unit);

	virtual bool CanMoveWhenDeployed();
	virtual bool CanFireWhenDeployed();
	virtual bool CanBuildWhenDeployed();
	virtual bool CanBuildWhenNotDeployed();
	
	virtual void Wait(int timeout);
	
	virtual void Stop();
	virtual void Move(Position p);
	virtual void MoveAndFire(Position p);

	virtual bool Build(IUnitType* t);
	virtual bool Build(std::string typeName);
	virtual bool Build(std::string typeName, Position p);
	virtual bool Build(IUnitType* t, Position p);

	virtual bool AreaReclaim(Position p, double radius);
	virtual bool Reclaim(IMapFeature* mapFeature);
	virtual bool Reclaim(IUnit* unit);
	virtual bool Attack(IUnit* unit);
	virtual bool Repair(IUnit* unit);


	virtual bool MorphInto(IUnitType* t);


	virtual Position GetPosition();
	
	virtual float GetHealth();
	virtual float GetMaxHealth();

	virtual int WeaponCount();

	virtual float MaxWeaponsRange();

	virtual bool CanBuild(IUnitType* t);
	virtual bool IsBeingBuilt();

	virtual SResourceTransfer GetResourceUsage(int idx);

	virtual void ExecuteCustomCommand(int cmdId, std::vector<float> params_list, short options, int timeOut);

protected:
	
	springai::OOAICallback* callback;
	springai::Unit* unit;
	bool dead;
	IGame* game;
};
