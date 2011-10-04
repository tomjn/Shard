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

	virtual float ReclaimSpeed();
	virtual bool Extractor();

	virtual float ResourceCost(int idx);

	virtual float GetMaxHealth();

	virtual int WeaponCount();
	virtual float MaxWeaponDamage();

	springai::UnitDef* GetUnitDef();

	virtual std::vector<IUnitType*> BuildOptions();
	
protected:
	std::vector<springai::UnitDef*> boptions;
	CSpringGame* game;
	springai::AICallback* callback;
	springai::UnitDef* unitDef;
};
