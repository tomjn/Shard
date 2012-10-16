#pragma once

class IUnitType {
public:
	virtual ~IUnitType(){}
	virtual std::string Name()=0;

	virtual float ReclaimSpeed()=0;
	virtual bool Extractor()=0;
	virtual float ResourceCost(int idx)=0;

	virtual float GetMaxHealth()=0;

	virtual int WeaponCount()=0;

	virtual float MaxWeaponDamage()=0;

	virtual std::vector<IUnitType*> BuildOptions()=0;

};
