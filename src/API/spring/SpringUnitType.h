#pragma once

class CSpringUnitType;

#include "../interfaces/IUnitType.h"
#include <vector>
#include "SpringGame.h"

class CSpringUnitType : public IUnitType {
public:
	CSpringUnitType(CSpringGame* game, springai::AICallback* callback, springai::UnitDef* unitDef);
	virtual ~CSpringUnitType();

	virtual std::string Name();

	virtual bool CanDeploy();
	virtual bool CanMoveWhenDeployed();
	virtual bool CanFireWhenDeployed();
	virtual bool CanBuildWhenDeployed();
	virtual bool CanBuildWhenNotDeployed();

	virtual bool Extractor();

	virtual float GetMaxHealth();

	virtual int WeaponCount();

	springai::UnitDef* GetUnitDef();

	virtual std::vector<IUnitType*> BuildOptions();
	
protected:
	std::vector<springai::UnitDef*> boptions;
	springai::AICallback* callback;
	springai::UnitDef* unitDef;
	CSpringGame* game;
};
