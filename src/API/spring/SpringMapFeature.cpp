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
