#include "spring_api.h"
#include "WrappResource.h"
#include "ExternalAI/Interface/AISCommands.h" // for UNIT_COMMAND_BUILD_NO_FACING

CSpringUnit::CSpringUnit(springai::OOAICallback* callback, springai::Unit* u, IGame* game)
: callback(callback), unit(u), dead(false), game(game){
	//
	
}

CSpringUnit::~CSpringUnit(){
	//
}

int CSpringUnit::ID(){
	return unit->GetUnitId();
}

std::string CSpringUnit::Name(){
	springai::UnitDef* u = unit->GetDef();
	if(u){
		return u->GetName();
	}else{
		return "";
	}
}

void CSpringUnit::SetDead(bool dead){
	this->dead = dead;
}

bool CSpringUnit::IsAlive(){
	return dead;
}

bool CSpringUnit::IsCloaked(){
	return this->unit->IsCloaked();
}

void CSpringUnit::Forget(){
	return;
}

bool CSpringUnit::Forgotten(){
	return false;
}


IUnitType* CSpringUnit::Type(){
	return 0;
}


bool CSpringUnit::CanMove(){
	return unit->GetDef()->IsAbleToMove();
}

bool CSpringUnit::CanDeploy(){
	return false;
}

bool CSpringUnit::CanBuild(){
	return (unit->GetDef()->GetBuildOptions().size() > 0);
}


bool CSpringUnit::CanMorph(){
	return false;
}


bool CSpringUnit::CanAssistBuilding(IUnit* unit){
	return this->unit->GetDef()->IsAbleToAssist();
}


bool CSpringUnit::CanMoveWhenDeployed(){
	return false;
}

bool CSpringUnit::CanFireWhenDeployed(){
	return false;
}

bool CSpringUnit::CanBuildWhenDeployed(){
	return false;
}

bool CSpringUnit::CanBuildWhenNotDeployed(){
	return false;
}





void CSpringUnit::Stop(){
	this->unit->Stop();
}

void CSpringUnit::Move(Position p){
	const springai::AIFloat3 pos(p.x, p.y, p.z);
	this->unit->MoveTo(pos);
}

void CSpringUnit::MoveAndFire(Position p){
	const springai::AIFloat3 pos(p.x, p.y, p.z);
	this->unit->Fight(pos);
}

bool CSpringUnit::Build(IUnitType* t){
	Position p = this->GetPosition();
	CSpringUnitType* type = (CSpringUnitType*)t;
	springai::UnitDef* ud = type->GetUnitDef();
	if(ud->GetType() == std::string("factory")){
		return Build(t,p);
	}else{
		int xs = ud->GetXSize();
		double dsp = 200.0/double(xs);
		p = game->Map()->FindClosestBuildSite(t,p,1500,dsp);
		return Build(t,p);
	}
}

bool CSpringUnit::Build(std::string typeName){
	IUnitType* t = game->GetTypeByName(typeName);
	if(t){
		return Build(t);
	}
	return false;
}

bool CSpringUnit::Build(std::string typeName, Position p){
	IUnitType* t = game->GetTypeByName(typeName);
	return Build(t,p);
}

bool CSpringUnit::Build(IUnitType* t, Position p){
	CSpringUnitType* st = (CSpringUnitType*)t;
	springai::UnitDef* ud = st->GetUnitDef();
	const springai::AIFloat3 pos(p.x, p.y, p.z);
	this->unit->Build(ud, pos, UNIT_COMMAND_BUILD_NO_FACING, 0, 10000);
	return true;
}

bool CSpringUnit::Reclaim(IMapFeature* mapFeature){
	springai::Feature* f = ((CSpringMapFeature*)mapFeature)->feature;
	this->unit->ReclaimFeature(f);
	return true;
}

bool CSpringUnit::AreaReclaim(Position p, double radius){
	const springai::AIFloat3 pos(p.x, p.y, p.z);
	this->unit->ReclaimInArea(pos, radius);
	return true;
}

bool CSpringUnit::Reclaim(IUnit* unit){
	springai::Unit* u = ((CSpringUnit*)unit)->unit;
	this->unit->ReclaimUnit(u);
	return true;
}

bool CSpringUnit::Attack(IUnit* unit){
	springai::Unit* u = ((CSpringUnit*)unit)->unit;
	this->unit->Attack(u);
	return true;
}

bool CSpringUnit::Repair(IUnit* unit){
	springai::Unit* u = ((CSpringUnit*)unit)->unit;
	this->unit->Attack(u);
	return true;
}

Position CSpringUnit::GetPosition(){
	Position p;
	const springai::AIFloat3 pos = unit->GetPos();
	p.x = pos.x;
	p.y = pos.y;
	p.z = pos.z;
	return p;
}

float CSpringUnit::GetHealth(){
	return unit->GetHealth();
}

float CSpringUnit::GetMaxHealth(){
	return unit->GetMaxHealth();
}

int CSpringUnit::WeaponCount(){
	return unit->GetDef()->GetWeaponMounts().size();
}

float CSpringUnit::MaxWeaponsRange(){
	return unit->GetMaxRange();
}

bool CSpringUnit::CanBuild(IUnitType* t){
	if(t == 0){
		return false;
	}
	if(unit == 0){
		return false;
	}
	if(unit->GetDef() == 0){
		return false;
	}
	std::vector<springai::UnitDef*> options = unit->GetDef()->GetBuildOptions();
	if(!options.empty()){
		//
		std::vector<springai::UnitDef*>::iterator i = options.begin();
		for(;i != options.end();++i){
			springai::UnitDef* u = *i;
			if( u->GetName() == t->Name()){
				return true;
			}
		}

	}
	return false;
}

SResourceTransfer CSpringUnit::GetResourceUsage(int idx){
	springai::Resource* r = springai::WrappResource::GetInstance(callback->GetSkirmishAIId(), idx);
	SResourceTransfer rt;
	rt.consumption = this->unit->GetResourceUse(r);
	rt.generation = this->unit->GetResourceMake(r);
	rt.rate = 1;
	rt.resource = game->GetResource(idx);
	rt.gameframe = game->Frame();
	return rt;
}
