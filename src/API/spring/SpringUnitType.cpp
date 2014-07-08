#include "spring_api.h"

#include "AI/Wrappers/Cpp/src-generated/Engine.h"
#include "AI/Wrappers/Cpp/src-generated/OOAICallback.h"
#include "ExternalAI/Interface/AISEvents.h"
#include "ExternalAI/Interface/AISCommands.h"
#include "AI/Wrappers/Cpp/src-generated/UnitDef.h"
#include "AI/Wrappers/Cpp/src-generated/WeaponMount.h"
#include "AI/Wrappers/Cpp/src-generated/WeaponDef.h"
#include "AI/Wrappers/Cpp/src-generated/Damage.h"
#include "SpringGame.h"
#include "SpringUnitType.h"

CSpringUnitType::CSpringUnitType(CSpringGame* game, springai::OOAICallback* callback, springai::UnitDef* unitDef):
	boptions(unitDef->GetBuildOptions()),
	game(game),
	callback(callback),
	unitDef(unitDef),
	resources(callback->GetResources()),
	weaponMounts(unitDef->GetWeaponMounts())
{
}

CSpringUnitType::~CSpringUnitType(){
	game = NULL;
	callback = NULL;
	delete unitDef; //same as in SpringUnit.cpp
	unitDef = NULL;
	for (int i = 0; i < resources.size(); i += 1) {
		delete resources[i];
	}
	for (int i = 0; i < weaponMounts.size(); i += 1) {
		delete weaponMounts[i];
	}
	for (int i = 0; i < boptions.size(); i += 1) {
		delete boptions[i];
	}
}

std::string CSpringUnitType::Name(){
	return this->unitDef->GetName();
}

float CSpringUnitType::ReclaimSpeed(){
	return unitDef->GetReclaimSpeed();
}

float CSpringUnitType::ResourceCost(int idx){
	if(!resources.empty()){
		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			if(r->GetResourceId() == idx){
				return unitDef->GetCost(r);
			}
		}
	}
	return -1;
}

bool CSpringUnitType::Extractor(){
	springai::Resource* r = static_cast<CSpringMap*>(game->Map())->GetMetalResource();
	return unitDef->GetResourceExtractorRange(r);
}

float CSpringUnitType::GetMaxHealth(){
	return unitDef->GetHealth();
}

int CSpringUnitType::WeaponCount(){
	return weaponMounts.size();
}

float CSpringUnitType::MaxWeaponDamage(){
	if(!weaponMounts.empty()){
		float output = 0;
		std::vector<springai::WeaponMount*>::iterator i = weaponMounts.begin();
		for(; i != weaponMounts.begin();++i){
			springai::WeaponMount* m = *i;
			springai::WeaponDef* def = m->GetWeaponDef();
			springai::Damage* d = def->GetDamage();
			float damage = *(d->GetTypes().begin());
			output += damage;
			delete d;
			delete def;
		}
		return output;
	}
	return 0;
}

springai::UnitDef* CSpringUnitType::GetUnitDef(){
	return unitDef;
}

std::vector<IUnitType*> CSpringUnitType::BuildOptions(){
	std::vector<IUnitType*> options;

	std::vector<springai::UnitDef*> defs = unitDef->GetBuildOptions();
	if(!defs.empty()){
		std::vector<springai::UnitDef*>::iterator i = defs.begin();
		for(;i!= defs.end();++i){
			springai::UnitDef* u = *i;
			IUnitType* ut = game->ToIUnitType(u);
			options.push_back(ut);
			delete u;
		}
	}
	return options;
}
