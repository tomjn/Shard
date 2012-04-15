#include "spring_api.h"
#include "AI/Wrappers/Cpp/src-generated/WrappResource.h"
#include "ExternalAI/Interface/AISCommands.h" // for UNIT_COMMAND_BUILD_NO_FACING
#include <vector>

CSpringUnit::CSpringUnit(springai::OOAICallback* callback, springai::Unit* u, IGame* game)
: callback(callback), unit(u), dead(false), game(game){
	if(u == 0){
		throw std::runtime_error("springai::unit must never be null when passed into the constructor of a CSpringUnit object! Bad bad coder");
	}
	
}

CSpringUnit::~CSpringUnit(){
	//
}

int CSpringUnit::ID(){
	return unit->GetUnitId();
}

int CSpringUnit::Team(){
	return unit->GetTeam();
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
	if(ud){
		if((!ud->IsAbleToMove())&&(ud->GetType() == std::string("factory"))){
			return Build(t,p);
		}else{
			int ms = std::max(ud->GetXSize(),ud->GetZSize());
			double dsp = 6;
			double radius = 500;
			if(ms < 4){
				radius = 900;
				dsp = 8;
			} else if(ms > 8){
				radius = 900;
				dsp = 5;
			} else if (ms > 15){
				radius = 1800;
				dsp=3;
			}
			if(ud->IsNeedGeo()){
				radius = 3000;
			}
			p = game->Map()->FindClosestBuildSite(t,p,radius,dsp);
			return Build(t,p);
		}
	} else{
		return false;
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
/*
[23:19:39] <[RoX]knorke> who/whatever wants to use the custom commands (morph,jump,...) must know the numbers
[23:20:14] <[RoX]knorke> http://code.google.com/p/conflictterra/source/browse/games/CT/LuaRules/Gadgets/unit_morph.lua
[23:20:20] <[RoX]knorke> local CMD_MORPH_STOP = 32210
[23:20:21] <[RoX]knorke> local CMD_MORPH = 31210
[23:20:47] <[RoX]knorke> http://code.google.com/p/conflictterra/source/browse/games/CT/LuaRules/Gadgets/Jumpjets_lua.lua
[23:20:55] <[RoX]knorke> local CMD_JUMP = 38521
*/
bool CSpringUnit::MorphInto(IUnitType* t){
	std::vector<float> params_list;
	unit->ExecuteCustomCommand(31210, params_list);
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


void CSpringUnit::ExecuteCustomCommand(int cmdId, std::vector<float> params_list, short options = 0, int timeOut = INT_MAX){
	this->unit->ExecuteCustomCommand(cmdId,params_list,options,timeOut);
}
