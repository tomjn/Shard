#include "spring_api.h"
#include "AI/Wrappers/Cpp/src-generated/WrappResource.h"
#include "AI/Wrappers/Cpp/src-generated/WrappWeaponMount.h"
#include "ExternalAI/Interface/AISCommands.h" // for UNIT_COMMAND_BUILD_NO_FACING
#include <vector>

CSpringUnit::CSpringUnit(springai::OOAICallback* callback, springai::Unit* u, CSpringGame* game)
: callback(callback), unit(u), dead(false), game(game) {
	if(u == 0){
		throw std::runtime_error("springai::unit must never be null when passed into the constructor of a CSpringUnit object! Bad bad coder");
	}
	def = u->GetDef();
	if(def) {
		buildoptions = def->GetBuildOptions();
	} else {
		game->SendToConsole("shard-runtime warning: UnitDef was NULL in CSpringUnit.");
	}
}

CSpringUnit::~CSpringUnit(){
	delete unit;
	unit = NULL;
	callback = NULL;
	//
	delete def;
	def = NULL;
	for (int i = 0; i < buildoptions.size(); i += 1) {
		delete buildoptions[i];
	}
}

int CSpringUnit::ID(){
	if (unit==NULL) {
		return -1;
	}
	return unit->GetUnitId();
}

int CSpringUnit::Team(){
	return unit->GetTeam();
}

std::string CSpringUnit::Name(){
	if (unit == NULL) {
		return "";
	}
	springai::UnitDef* u = def;
	if(u == NULL){
		return "";
	}
	return u->GetName();
}

void CSpringUnit::SetDead(bool dead){
	this->dead = dead;
}

bool CSpringUnit::IsAlive(){
	return dead;
}

bool CSpringUnit::IsAlly(int allyTeamId) {
	if (!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in IsAlly");
		return false;
	}
	return allyTeamId == unit->GetAllyTeam();
}

bool CSpringUnit::IsCloaked(){
	if (!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in IsCloaked");
		return false;
	}
	return this->unit->IsCloaked();
}

void CSpringUnit::Forget(){
	return;
}

bool CSpringUnit::Forgotten(){
	return false;
}

IUnitType* CSpringUnit::Type(){
	IUnitType* t = game->ToIUnitType( def );
	return t;
}


bool CSpringUnit::CanMove(){
	if (def != NULL)
		return def->IsAbleToMove();
	game->SendToConsole("shard-runtime warning: UnitDef was NULL in CanMove");
	return false;
}

bool CSpringUnit::CanDeploy(){
	return false;
}

bool CSpringUnit::CanBuild(){
	if (def != NULL) {
		return (buildoptions.size() > 0);
	}
	game->SendToConsole("shard-runtime warning: UnitDef was NULL in CanBuild");
	return false;
}


bool CSpringUnit::CanAssistBuilding(IUnit* unit){
	if (def != NULL)
		return def->IsAbleToAssist();
	game->SendToConsole("shard-runtime warning: UnitDef was NULL in CanAssistBuilding");
	return false;
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



void CSpringUnit::Wait(int timeout){
	if (!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in Wait");
		return;
	}

	this->unit->Wait(timeout);
}

void CSpringUnit::Stop(){
	if (!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in Stop");
		return;
	}

	this->unit->Stop();
}

void CSpringUnit::Move(Position p){
	if (!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in Move");
		return;
	}

	const springai::AIFloat3 pos(p.x, p.y, p.z);
	try {
		this->unit->MoveTo(pos);
	} catch (springai::CallbackAIException& e) {
		game->SendToConsole(std::string("shard-runtime warning: Failed in MoveTo. Reason: ") + std::string(e.what()));
	}
}

void CSpringUnit::MoveAndFire(Position p){
	if (!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in MoveAndFire");
		return;
	}

	const springai::AIFloat3 pos(p.x, p.y, p.z);
	this->unit->Fight(pos);
}

bool CSpringUnit::Build(IUnitType* t){
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in Build(IUnitType)");
		return false;
	}

	Position p = this->GetPosition();
	CSpringUnitType* type = static_cast<CSpringUnitType*>(t);
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
	return Build(t,p,UNIT_COMMAND_BUILD_NO_FACING);
}

bool CSpringUnit::Build(IUnitType* t, Position p){
	return Build(t,p,UNIT_COMMAND_BUILD_NO_FACING);
}

bool CSpringUnit::Build(std::string typeName, Position p, int facing){
	IUnitType* t = game->GetTypeByName(typeName);
	return Build(t,p,facing);
}

bool CSpringUnit::Build(IUnitType* t, Position p, int facing){
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in Build(IUnitType, Position, int)");
		return false;
	}
	if(t){
		CSpringUnitType* st = static_cast<CSpringUnitType*>(t);
		springai::UnitDef* ud = st->GetUnitDef();
		const springai::AIFloat3 pos(p.x, p.y, p.z);

		if(this->game->Map()->CanBuildHereFacing(t,p,facing)){
			try {
				this->unit->Build(ud, pos, facing, 0, 10000);
			} catch(...){
				return false;
			}
			return true;
		} else {
			return false;
		}
	} else {
		return false;
	}
}

bool CSpringUnit::Reclaim(IMapFeature* mapFeature){
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in Reclaim(IMapFeature)");
		return false;
	}
	springai::Feature* f = static_cast<CSpringMapFeature*>(mapFeature)->feature;
	this->unit->ReclaimFeature(f);
	return true;
}

bool CSpringUnit::AreaReclaim(Position p, double radius){
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in AreaReclaim");
		return false;
	}
	const springai::AIFloat3 pos(p.x, p.y, p.z);
	this->unit->ReclaimInArea(pos, radius);
	return true;
}

bool CSpringUnit::Reclaim(IUnit* unit){
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in Reclaim");
		return false;
	}
	springai::Unit* u = static_cast<CSpringUnit*>(unit)->unit;
	this->unit->ReclaimUnit(u);
	return true;
}

bool CSpringUnit::Attack(IUnit* unit){
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in Attack");
		return false;
	}
	springai::Unit* u = static_cast<CSpringUnit*>(unit)->unit;
	this->unit->Attack(u);
	return true;
}

bool CSpringUnit::Repair(IUnit* unit){
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in Repair");
		return false;
	}
	springai::Unit* u = static_cast<CSpringUnit*>(unit)->unit;
	this->unit->Repair(u);
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
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in MorphInto");
		return false;
	}
	std::vector<float> params_list;
	unit->ExecuteCustomCommand(31210, params_list);
	return true;
}

Position CSpringUnit::GetPosition(){
	Position p;
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in GetPosition");
		return p;
	}
	const springai::AIFloat3 pos = unit->GetPos();
	p.x = pos.x;
	p.y = pos.y;
	p.z = pos.z;
	return p;
}


bool CSpringUnit::IsBeingBuilt(){
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in IsBeingBuilt");
		return false;
	}
	return unit->IsBeingBuilt();
}

float CSpringUnit::GetHealth(){
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in GetHealth");
		return 0.0f;
	}
	return unit->GetHealth();
}

float CSpringUnit::GetMaxHealth(){
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in GetMaxHealth");
		return 0.0f;
	}
	return unit->GetMaxHealth();
}

int CSpringUnit::WeaponCount(){
	if (def != NULL) {
		std::vector<springai::WeaponMount*> wm = def->GetWeaponMounts();
		int n = wm.size();
		for (int i = 0; i < wm.size(); i += 1) {
			delete wm[i];
		}
		return n;
	}
	return 0;
}

float CSpringUnit::MaxWeaponsRange(){
	if(!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in MaxWeaponsRange");
		return 0.0f;
	}
	return unit->GetMaxRange();
}

bool CSpringUnit::CanBuild(IUnitType* t){
	if(t == 0){
		return false;
	}
	if(unit == 0){
		game->SendToConsole("shard-runtime warning: Unit was NULL in CanBuild");
		return false;
	}
	if(def == 0){
		return false;
	}
	std::vector<springai::UnitDef*> options = buildoptions;
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
	if (!unit) {
		game->SendToConsole("shard-runtime warning: Unit was NULL in ExecuteCustomCommand");
		return;
	}
	try {
		this->unit->ExecuteCustomCommand(cmdId,params_list,options,timeOut);
	} catch (springai::CallbackAIException& e) {
		game->SendToConsole(std::string("shard-runtime warning: Failed to executeCustomCommand. Reason: ") + std::string(e.what()));
	}
}
