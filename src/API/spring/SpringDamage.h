#pragma once

class CSpringDamage;

#include "../interfaces/IDamage.h"
#include "SpringGame.h"

class CSpringDamage : public IDamage {
public:
	typedef boost::shared_ptr<CSpringDamage> Ptr;

	CSpringDamage(CSpringGame* game, springai::OOAICallback* callback, SUnitDamagedEvent* evt);
	virtual ~CSpringDamage();

	virtual float Damage();
	virtual Position Direction();
	virtual std::string DamageType();
	virtual std::string WeaponType();
	virtual IUnit* Attacker();
	virtual std::vector<std::string> Effects();


protected:
	CSpringGame* game;
	springai::OOAICallback* callback;
	float damage;
	Position direction;
	std::string weaponType;
	std::string damageType;
	IUnit* attacker;
	std::vector<std::string> effects;
};

