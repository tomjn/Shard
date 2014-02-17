
#include "spring_api.h"

#include <iterator>
#include <stdlib.h>

#include "SpringUnitType.h"
#include "SpringMap.h"

#include "ExternalAI/Interface/AISCommands.h" // for UNIT_COMMAND_BUILD_NO_FACING

CSpringMap::CSpringMap(springai::OOAICallback* callback, CSpringGame* game)
:	callback(callback),
	game(game),
	metal(NULL), map(callback->GetMap()), lastMapFeaturesUpdate(-1)	{

	std::vector<springai::Resource*> resources = callback->GetResources();
	if ( !resources.empty() ) {

		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			std::string name = r->GetName();
			if(name == "Metal"){
				this->metal = r;
				break;
			} else {
				delete r;
			}
		}
	}

	if(metal){
		this->GetMetalSpots();
	}
}

CSpringMap::~CSpringMap(){
	this->metalspots.clear();
	game = NULL;
	callback = NULL;
	delete map;
	map = NULL;
	delete metal;
	for (std::vector<IMapFeature*>::iterator i = mapFeatures.begin(); i != mapFeatures.end(); ++i) {
		delete (*i);
	}
	mapFeatures.clear();
}

Position CSpringMap::FindClosestBuildSite(IUnitType* t, Position builderPos, double searchRadius, double minimumDistance){
	return this->FindClosestBuildSiteFacing(t,builderPos,searchRadius,minimumDistance,UNIT_COMMAND_BUILD_NO_FACING);
}

Position CSpringMap::FindClosestBuildSiteFacing(IUnitType* t, Position builderPos, double searchRadius, double minimumDistance,int facing){
	if ((t == NULL) || (callback==NULL)){
		return Position(0.0f, 1.0f, 0.0f);
	}
	CSpringUnitType* ut = static_cast<CSpringUnitType*>(t);
	const springai::AIFloat3 bPos(builderPos.x, builderPos.y, builderPos.z);
	const springai::AIFloat3 pos = map->FindClosestBuildSite(ut->GetUnitDef(), bPos, searchRadius, minimumDistance, facing);
	Position p;
	p.x = pos.x;
	p.y = pos.y;
	p.z = pos.z;
	return p;
}

bool CSpringMap::CanBuildHere(IUnitType* t, Position p){
	return this->CanBuildHereFacing(t,p,UNIT_COMMAND_BUILD_NO_FACING);
}

bool CSpringMap::CanBuildHereFacing(IUnitType* t, Position p, int facing){
	CSpringUnitType* ut = static_cast<CSpringUnitType*>(t);
	const springai::AIFloat3 pos(p.x, p.y, p.z);
	return map->IsPossibleToBuildAt( ut->GetUnitDef(), pos, facing );
}

int CSpringMap::SpotCount(){
	return metalspots.size();
}

Position CSpringMap::GetSpot(int idx){
	return metalspots[idx];
}

std::vector<Position>& CSpringMap::GetMetalSpots(){
	metal = this->GetMetalResource();
	metalspots.clear();
	std::vector<springai::AIFloat3> positions = map->GetResourceMapSpotsPositions( metal );
	if ( !positions.empty() ) {
		std::vector<springai::AIFloat3>::iterator j = positions.begin();
		for(;j != positions.end();++j){
			Position p;
			p.x = j->x;
			p.y = j->y;
			p.z = j->z;
			metalspots.push_back(p);
		}
	}
	return metalspots;
}

Position CSpringMap::MapDimensions(){
	Position p;
	p.x = map->GetWidth();
	p.z = map->GetHeight();

	return p;
}

std::string CSpringMap::MapName(){
	return map->GetName();
}

float CSpringMap::MaximumHeight(){
	return map->GetMaxHeight();
}

float CSpringMap::MinimumHeight(){
	return map->GetMinHeight();
}

double CSpringMap::AverageWind(){
	float minwind = map->GetMinWind();
	float maxwind = map->GetMaxWind();
	return (minwind+maxwind)/2;
}

double CSpringMap::MinimumWindSpeed(){
	return map->GetMinWind();
}

double CSpringMap::MaximumWindSpeed(){
	return map->GetMaxWind();
}

double CSpringMap::TidalStrength(){
	return map->GetTidalStrength();
}

std::vector<IMapFeature*>::iterator CSpringMap::GetMapFeatureIteratorById(int id) {
	for (std::vector<IMapFeature*>::iterator i = mapFeatures.begin(); i != mapFeatures.end(); ++i) {
		if ((*i)->ID() == id) {
			return i;
		}
	}
	return mapFeatures.end();
}

void CSpringMap::UpdateMapFeatures() {
	std::vector<IMapFeature*> newMapFeatures;
	if(lastMapFeaturesUpdate != game->Frame()) {
		std::vector<springai::Feature*> features = callback->GetFeatures();
		std::vector<springai::Feature*>::iterator i = features.begin();

		for(;i != features.end(); ++i){
			std::vector<IMapFeature*>::iterator obj = GetMapFeatureIteratorById((*i)->GetFeatureId());
			if(obj != mapFeatures.end()) { //feature was already present, keep old object.
				newMapFeatures.push_back(*obj);
				mapFeatures.erase(obj); //remove from old map.
			} else { //feature was not yet presend, add new one.
				CSpringMapFeature* f = new CSpringMapFeature(callback,*i,game);
				newMapFeatures.push_back(f);
			}
		}

		//clear up old features that spring api did not deliver => they got deleted.
		for(std::vector<IMapFeature*>::iterator i = mapFeatures.begin(); i != mapFeatures.end(); ++i) {
			delete (*i);
		}

		mapFeatures = newMapFeatures;
		lastMapFeaturesUpdate = game->Frame();
	}
}

std::vector<IMapFeature*> CSpringMap::GetMapFeatures(){
	UpdateMapFeatures();
	return mapFeatures;
}

std::vector<IMapFeature*> CSpringMap::GetMapFeaturesAt(Position p, double radius){
	const springai::AIFloat3 pos(p.x, p.y, p.z);
	UpdateMapFeatures();
	std::vector<IMapFeature*> results;

	std::vector<springai::Feature*> features = callback->GetFeaturesIn(pos,radius);
	std::vector<springai::Feature*>::iterator i = features.begin();
	for(;i != features.end(); ++i){
		std::vector<IMapFeature*>::iterator obj = GetMapFeatureIteratorById((*i)->GetFeatureId());
		if(obj != mapFeatures.end()) {
			results.push_back(*obj);
		} else { //can this ever happen?
			CSpringMapFeature* f = new CSpringMapFeature(callback,*i,game);
			mapFeatures.push_back(f);
			results.push_back(f);
		}
	}
	return results;
}

springai::Resource* CSpringMap::GetMetalResource(){
	return metal;
}
