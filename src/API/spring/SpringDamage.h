#pragma once

class CSpringDamage;

#include "../interfaces/IDamage.h"
#include "SpringGame.h"

class CSpringDamage : public IDamage {
public:
	typedef boost::shared_ptr<CSpringDamage> Ptr;

	CSpringDamage(CSpringGame* game, springai::OOAICallback* callback, SUnitDamagedEvent* evt);
	virtual ~CSpringDamage() override;

	virtual float Damage() override;
	virtual Position Direction() override;
	virtual std::string DamageType() override;
	virtual std::string WeaponType() override;
	virtual IUnit* Attacker() override;
	virtual std::vector<std::string> Effects() override;


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

