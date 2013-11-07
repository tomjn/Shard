#include "spring_api.h"

CSpringMapFeature::CSpringMapFeature(springai::OOAICallback* callback, springai::Feature* f, IGame* game)
:feature(f),callback(callback),game(game){
	//
}

CSpringMapFeature::~CSpringMapFeature(){
	feature = NULL;
	callback = NULL;
	game = NULL;
}

int CSpringMapFeature::ID(){
	if (feature==NULL) {
		return -1;
	}
	return feature->GetFeatureId();
}

std::string CSpringMapFeature::Name(){
	if ((feature == NULL) || (feature->GetDef()==NULL)) {
		return "";
	}
	return feature->GetDef()->GetName();
}

Position CSpringMapFeature::GetPosition(){
	if (feature == NULL)
		return Position(0.0f,0.0f,0.0f);
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
	if (feature==NULL)
		return false;
	return feature->GetDef()->IsReclaimable();
}
