#pragma once

class CSpringUnitType;

#include "../interfaces/IUnitType.h"
#include <vector>
#include "SpringGame.h"

class CSpringUnitType : public IUnitType {
public:
	CSpringUnitType(CSpringGame* game, springai::OOAICallback* callback, springai::UnitDef* unitDef);
	virtual ~CSpringUnitType();

	virtual std::string Name() override;

	virtual float ReclaimSpeed() override;
	virtual bool Extractor() override;

	virtual float ResourceCost(int idx) override;

	virtual float GetMaxHealth() override;

	virtual int WeaponCount() override;
	virtual float MaxWeaponDamage() override;

	springai::UnitDef* GetUnitDef();

	virtual std::vector<IUnitType*> BuildOptions() override;
	
protected:
	std::vector<springai::UnitDef*> boptions;
	CSpringGame* game;
	springai::OOAICallback* callback;
	springai::UnitDef* unitDef;
	std::vector<springai::Resource*> resources;
	std::vector<springai::WeaponMount*> weaponMounts;
};
