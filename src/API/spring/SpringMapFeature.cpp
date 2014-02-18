#include "spring_api.h"

CSpringMapFeature::CSpringMapFeature(springai::OOAICallback* callback, springai::Feature* f, IGame* game)
:feature(f),callback(callback),game(game), def(f->GetDef()) {
	//
}

CSpringMapFeature::~CSpringMapFeature(){
	delete feature;
	feature = NULL;
	callback = NULL;
	game = NULL;
	delete def;
}

int CSpringMapFeature::ID(){
	if (feature==NULL) {
		return -1;
	}
	return feature->GetFeatureId();
}

std::string CSpringMapFeature::Name(){
	if ((feature == NULL) || (def==NULL)) {
		return "";
	}
	return def->GetName();
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
	float res = -1;
	if(!resources.empty()){
		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			if(r->GetResourceId() == idx){
				res = def->GetContainedResource(r);
			}
			delete r;
		}
	}
	return res;
}

bool CSpringMapFeature::Reclaimable(){
	if (feature==NULL || def == NULL)
		return false;
	return def->IsReclaimable();
}
