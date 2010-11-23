#include "spring_api.h"

#include <iterator>
#include <stdlib.h>

#include "SpringUnitType.h"
#include "SpringMap.h"

#include "ExternalAI/Interface/AISCommands.h" // for UNIT_COMMAND_BUILD_NO_FACING

CSpringMap::CSpringMap(springai::OOAICallback* callback, CSpringGame* game)
:	callback(callback),
	game(game),
	metal(NULL)	{

	metal = NULL;
	std::vector<springai::Resource*> resources = callback->GetResources();
	if(!resources.empty()){

		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			std::string name = r->GetName();
			if(name == "Metal"){
				this->metal = r;
				break;
			}
		}
	}

	
	if(metal){
		std::vector<springai::AIFloat3> positions = callback->GetMap()->GetResourceMapSpotsPositions(metal);
		if(!positions.empty()){
			std::vector<springai::AIFloat3>::iterator j = positions.begin();
			for(;j != positions.end();++j){
				Position p;
				p.x = j->x;
				p.y = j->y;
				p.z = j->z;
				metalspots.push_back(p);
			}
		}
	}
}

CSpringMap::~CSpringMap(){
	//
}


Position CSpringMap::FindClosestBuildSite(IUnitType* t, Position builderPos, double searchRadius, double minimumDistance){
	if(t == NULL){
		Position err;
		err.x = 0;
		err.y = 1;
		err.z = 0;
		return err;
	}
	CSpringUnitType* ut = (CSpringUnitType*)t;
	const springai::AIFloat3 bPos(builderPos.x, builderPos.y, builderPos.z);
	const springai::AIFloat3 pos = callback->GetMap()->FindClosestBuildSite(ut->GetUnitDef(), bPos, searchRadius, minimumDistance, 0);
	Position p;
	p.x = pos.x;
	p.y = pos.y;
	p.z = pos.z;
	return p;
}

bool CSpringMap::CanBuildHere(IUnitType* t, Position p){
	CSpringUnitType* ut = (CSpringUnitType*)t;
	const springai::AIFloat3 pos(p.x, p.y, p.z);
	return callback->GetMap()->IsPossibleToBuildAt(ut->GetUnitDef(), pos, UNIT_COMMAND_BUILD_NO_FACING);
}

int CSpringMap::SpotCount(){
	return metalspots.size();
}

Position CSpringMap::GetSpot(int idx){
	return metalspots[idx];
}

std::vector<Position>& CSpringMap::GetMetalSpots(){
	return metalspots;
}

Position CSpringMap::MapDimensions(){
	
	Position p;
	p.x = callback->GetMap()->GetWidth();
	p.z = callback->GetMap()->GetHeight();
	
	return p;
}

std::string CSpringMap::MapName(){
	return callback->GetMap()->GetName();
}

double CSpringMap::AverageWind(){
	float minwind = callback->GetMap()->GetMinWind();
	float maxwind = callback->GetMap()->GetMaxWind();
	return (minwind+maxwind)/2;
}

double CSpringMap::MinimumWindSpeed(){
	return callback->GetMap()->GetMinWind();
}

double CSpringMap::MaximumWindSpeed(){
	return callback->GetMap()->GetMaxWind();
}

double CSpringMap::TidalStrength(){
	return callback->GetMap()->GetTidalStrength();
}


std::vector<IMapFeature*> CSpringMap::GetMapFeatures(){
	std::vector< IMapFeature*> mapFeatures;
	
	std::vector<springai::Feature*> features = callback->GetFeatures();
	std::vector<springai::Feature*>::iterator i = features.begin();
	for(;i != features.end(); ++i){
		CSpringMapFeature* f = new CSpringMapFeature(callback,*i,game);
		mapFeatures.push_back(f);
	}
	return mapFeatures;
}

std::vector<IMapFeature*> CSpringMap::GetMapFeatures(Position p, double radius){
	const springai::AIFloat3 pos(p.x, p.y, p.z);
	std::vector< IMapFeature*> mapFeatures;
	
	std::vector<springai::Feature*> features = callback->GetFeaturesIn(pos,radius);
	std::vector<springai::Feature*>::iterator i = features.begin();
	for(;i != features.end(); ++i){
		CSpringMapFeature* f = new CSpringMapFeature(callback,*i,game);
		mapFeatures.push_back(f);
	}
	return mapFeatures;
}

springai::Resource* CSpringMap::GetMetalResource(){
	return metal;
}
