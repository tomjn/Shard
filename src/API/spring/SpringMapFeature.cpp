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
	return feature->GetDef()->GetName();
}

Position CSpringMapFeature::GetPosition(){
	const springai::AIFloat3 pos = feature->GetPosition();
	Position p;
	p.x = pos.x;
	p.y = pos.y;
	p.z = pos.z;
	return p;
}
