#include "spring_api.h"

CSpringMapFeature::CSpringMapFeature(springai::AICallback* callback, springai::Feature* f, IGame* game)
:callback(callback),feature(f),game(game){
	//
}

CSpringMapFeature::~CSpringMapFeature(){
	//
}

int CSpringMapFeature::ID(){
	return feature->GetFeatureId();
}

std::string CSpringMapFeature::Name(){
	return feature->GetDef()->GetName();
}

Position CSpringMapFeature::GetPosition(){
	SAIFloat3 p = feature->GetPosition();
	Position pos;
	pos.x = p.x;
	pos.y = p.y;
	pos.z = p.z;
	return pos;
}

float CSpringMapFeature::ResourceValue(int idx){
	std::vector<springai::Resource*> resources = callback->GetResources();
	if(!resources.empty()){
		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			if(r->GetResourceId() == idx){
				return feature->GetDef()->GetContainedResource(*r);
			}
		}
	}
	return -1;
}

bool CSpringMapFeature::Reclaimable(){
	return feature->GetDef()->IsReclaimable();
}
