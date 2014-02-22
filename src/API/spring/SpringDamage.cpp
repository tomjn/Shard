#include "spring_api.h"

#include <sstream>

#include "AI/Wrappers/Cpp/src-generated/Damage.h"
#include "AI/Wrappers/Cpp/src-generated/WrappDamage.h"
#include "AI/Wrappers/Cpp/src-generated/WeaponDef.h"
#include "AI/Wrappers/Cpp/src-generated/WrappWeaponDef.h"
#include "SpringGame.h"
#include "SpringDamage.h"

CSpringDamage::CSpringDamage(CSpringGame* game, springai::OOAICallback* callback, SUnitDamagedEvent* evt)
: game(game), callback(callback), damage(evt->damage), 
  direction(evt->dir_posF3[0], evt->dir_posF3[1], evt->dir_posF3[2]),
  attacker(game->GetUnitById(evt->attacker)) {

	if (evt->paralyzer) {
		effects.push_back("paralyzer");
	}

	//TODO: how to usefully fill damagatype? Or should be let LUA get damage type from weapontype?
	/*springai::Damage* dmg = springai::WrappDamage::GetInstance(callback->GetSkirmishAIId(), weaponType);
	std::vector<float> types = dmg->GetTypes();
	delete dmg;*/

	springai::WeaponDef* weapon = springai::WrappWeaponDef::GetInstance(callback->GetSkirmishAIId(), evt->weaponDefId);
	if (weapon) {
		weaponType = weapon->GetName();
		damageType = weapon->GetType();
		delete weapon;

	} else {
		std::stringstream msg;
		msg << "shard-runtime warning: Weapond def for " << evt->weaponDefId << " NULL.";
		game->SendToConsole(msg.str());
	}
}

CSpringDamage::~CSpringDamage(){
	game = NULL;
	callback = NULL;
}

float CSpringDamage::Damage() {
	return damage;
}

Position CSpringDamage::Direction() {
	return direction;
}

std::string CSpringDamage::DamageType() {
	return damageType;
}

std::string CSpringDamage::WeaponType() {
	return weaponType;
}

IUnit* CSpringDamage::Attacker() {
	return attacker;
}

std::vector<std::string> CSpringDamage::Effects() {
	return effects;
}

