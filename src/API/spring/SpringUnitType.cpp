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

CSpringUnitType::CSpringUnitType(CSpringGame* game, springai::OOAICallback* callback, springai::UnitDef* unitDef)
: game(game), callback(callback), unitDef(unitDef){
	boptions = unitDef->GetBuildOptions();
}

CSpringUnitType::~CSpringUnitType(){
	//
}

std::string CSpringUnitType::Name(){
	return this->unitDef->GetName();
}

float CSpringUnitType::ReclaimSpeed(){
	return unitDef->GetReclaimSpeed();
}

float CSpringUnitType::ResourceCost(int idx){
	std::vector<springai::Resource*> resources = callback->GetResources();
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
	springai::Resource* r = ((CSpringMap*)game->Map())->GetMetalResource();
	return unitDef->GetResourceExtractorRange(r);
}

float CSpringUnitType::GetMaxHealth(){
	return unitDef->GetHealth();
}

int CSpringUnitType::WeaponCount(){
	return unitDef->GetWeaponMounts().size();
}

float CSpringUnitType::MaxWeaponDamage(){
	std::vector<springai::WeaponMount*> weaponMounts = unitDef->GetWeaponMounts();
	if(weaponMounts.size() > 0){
		float output = 0;
		std::vector<springai::WeaponMount*>::iterator i = weaponMounts.begin();
		for(; i != weaponMounts.begin();++i){
			springai::WeaponMount* m = *i;
			float damage = *(m->GetWeaponDef()->GetDamage()->GetTypes().begin());
			output += damage;
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
		}
	}
	return options;
}
