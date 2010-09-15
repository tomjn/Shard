#include "spring_api.h"

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

bool CSpringUnitType::CanDeploy(){
	return false;
}

bool CSpringUnitType::CanMoveWhenDeployed(){
	return false;
}

bool CSpringUnitType::CanFireWhenDeployed(){
	return true;
}

bool CSpringUnitType::CanBuildWhenDeployed(){
	return true;
}

bool CSpringUnitType::CanBuildWhenNotDeployed(){
	return true;
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
