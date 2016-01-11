#pragma once

#include "../interfaces/IMapFeature.h"
#include "../interfaces/IUnit.h"
#include "../interfaces/IGame.h"

class CSpringUnit : public IUnit {
public:
	CSpringUnit(springai::OOAICallback* callback, springai::Unit* u, CSpringGame* game);
	virtual ~CSpringUnit();

	virtual int ID() override;
	virtual int Team() override;
	virtual std::string Name() override;

	virtual void SetDead(bool dead=true);
	virtual bool IsAlive() override;
	virtual bool IsAlly(int allyTeamId);

	virtual bool IsCloaked() override;

	virtual void Forget(); // makes the interface forget about this unit and cleanup
	virtual bool Forgotten(); // for interface/debugging use
	
	virtual IUnitType* Type() override;

	virtual bool CanMove() override;
	virtual bool CanDeploy() override;
	virtual bool CanBuild() override;
	
	virtual bool CanAssistBuilding(IUnit* unit) override;

	virtual bool CanMoveWhenDeployed() override;
	virtual bool CanFireWhenDeployed() override;
	virtual bool CanBuildWhenDeployed() override;
	virtual bool CanBuildWhenNotDeployed() override;
	
	virtual void Wait(int timeout) override;
	
	virtual void Stop() override;
	virtual void Move(Position p) override;
	virtual void MoveAndFire(Position p) override;

	virtual bool Build(IUnitType* t) override;
	virtual bool Build(std::string typeName) override;
	virtual bool Build(std::string typeName, Position p) override;
	virtual bool Build(IUnitType* t, Position p) override;

	virtual bool Build(std::string typeName, Position p, int facing) override;
	virtual bool Build(IUnitType* t, Position p, int facing) override;

	virtual bool AreaReclaim(Position p, double radius) override;
	virtual bool Reclaim(IMapFeature* mapFeature) override;
	virtual bool Reclaim(IUnit* unit) override;
	virtual bool Attack(IUnit* unit) override;
	virtual bool Repair(IUnit* unit) override;


	virtual bool MorphInto(IUnitType* t) override;


	virtual Position GetPosition() override;
	
	virtual float GetHealth() override;
	virtual float GetMaxHealth() override;

	virtual int WeaponCount() override;

	virtual float MaxWeaponsRange() override;

	virtual bool CanBuild(IUnitType* t) override;
	virtual bool IsBeingBuilt() override;

	virtual SResourceTransfer GetResourceUsage(int idx) override;

	virtual void ExecuteCustomCommand(int cmdId, std::vector<float> params_list, short options, int timeOut) override;

protected:
	
	springai::OOAICallback* callback;
	springai::Unit* unit;
	bool dead;
	CSpringGame* game;
	springai::UnitDef* def;
	std::vector<springai::UnitDef*> buildoptions;
};
