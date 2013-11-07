#include "spring_api.h"

CSpringMapFeature::CSpringMapFeature(springai::OOAICallback* callback, springai::Feature* f, IGame* game)
:feature(f),callback(callback),game(game){
	//
}

CSpringMapFeature::~CSpringMapFeature(){
	//
}

int CSpringMapFeature::ID(){
	return feature->GetFeatureId();
}

std::string CSpringMapFeature::Name(){
	if (feature->GetDef()!=NULL) {
		return feature->GetDef()->GetName();
	}
	return "";
}

Position CSpringMapFeature::GetPosition(){
	const springai::AIFloat3 pos = feature->GetPosition();
	Position p;
	p.x = pos.x;
	p.y = pos.y;
	p.z = pos.z;
	return p;
}

float CSpringMapFeature::ResourceValue(int idx){
	std::vector<springai::Resource*> resources = callback->GetResources();
	if(!resources.empty()){
		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			if(r->GetResourceId() == idx){
				return feature->GetDef()->GetContainedResource(r);
			}
		}
	}
	return -1;
}

bool CSpringMapFeature::Reclaimable(){
	return feature->GetDef()->IsReclaimable();
}
