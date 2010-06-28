#include "spring_api.h"

#include "AICallback.h"

#include "ExternalAI/Interface/AISEvents.h"
#include "ExternalAI/Interface/AISCommands.h"

#include <iterator>
#include <stdlib.h>

#include "Unit.h"
#include "UnitDef.h"
#include "Engine.h"
#include "DataDirs.h"
#include "Map.h"
#include "Mod.h"
#include "Game.h"
#include "Cheats.h"
#include "Economy.h"
#include "Resource.h"

#include "SpringUnitType.h"
#include "SpringMap.h"

CSpringMap::CSpringMap(springai::AICallback* callback, CSpringGame* game)
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
		std::vector<SAIFloat3> positions = callback->GetMap()->GetResourceMapSpotsPositions(*metal,0);
		if(!positions.empty()){
			std::vector<SAIFloat3>::iterator j = positions.begin();
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
	CSpringUnitType* ut = (CSpringUnitType*)t;
	SAIFloat3 p;
	p.x = builderPos.x;
	p.y = builderPos.y;
	p.z = builderPos.z;
	p = callback->GetMap()->FindClosestBuildSite(*(ut->GetUnitDef()),p,searchRadius,minimumDistance,0);
	Position pos;
	pos.x = p.x;
	pos.y = p.y;
	pos.z = p.z;
	return pos;
}

bool CSpringMap::CanBuildHere(IUnitType* t, Position pos){
	CSpringUnitType* ut = (CSpringUnitType*)t;
	SAIFloat3 p;
	p.x = pos.x;
	p.y = pos.y;
	p.z = pos.z;
	return callback->GetMap()->IsPossibleToBuildAt(*(ut->GetUnitDef()),p,UNIT_COMMAND_BUILD_NO_FACING);
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
	SAIFloat3 pos;
	pos.x = p.x;
	pos.y = p.y;
	pos.z = p.z;
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
