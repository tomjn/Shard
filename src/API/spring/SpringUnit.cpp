#include "spring_api.h"

CSpringUnit::CSpringUnit(springai::AICallback* callback, springai::Unit* u, IGame* game)
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
	SStopUnitCommand c;
	c.unitId = this->unit->GetUnitId();
	callback->GetEngine()->HandleCommand(callback->GetTeamId(),-1,COMMAND_UNIT_STOP,&c);
}

void CSpringUnit::Move(Position p){
	SMoveUnitCommand c;
	c.unitId = this->unit->GetUnitId();
	c.toPos.x = p.x;
	c.toPos.y = p.y;
	c.toPos.z = p.z;
	callback->GetEngine()->HandleCommand(callback->GetTeamId(),-1,COMMAND_UNIT_MOVE,&c);
	
}

void CSpringUnit::MoveAndFire(Position p){
	SFightUnitCommand c;
	c.unitId = this->unit->GetUnitId();
	c.toPos.x = p.x;
	c.toPos.y = p.y;
	c.toPos.z = p.z;
	callback->GetEngine()->HandleCommand(callback->GetTeamId(),-1,COMMAND_UNIT_FIGHT,&c);
}

bool CSpringUnit::Build(IUnitType* t){
	Position p = this->GetPosition();
	CSpringUnitType* type = (CSpringUnitType*)t;
	springai::UnitDef* ud = type->GetUnitDef();
	if(ud){
		if((!ud->IsAbleToMove())&&(ud->GetType() == std::string("factory"))){
			return Build(t,p);
		}else{
			int xs = ud->GetXSize();
			int ms = std::max(ud->GetXSize(),ud->GetZSize());
			double dsp = 5;
			double radius = 500;
			if(ms > 8){
				radius = 900;
				dsp = 4;
			} else if (ms > 15){
				radius = 1800;
				dsp=2;
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
	//
	SBuildUnitCommand c;

	CSpringUnitType* st = (CSpringUnitType*)t;
	c.toBuildUnitDefId = st->GetUnitDef()->GetUnitDefId();
	c.buildPos.x = p.x;
	c.buildPos.y = p.y;
	c.buildPos.z = p.z;
	c.timeOut = 10000;
	c.options = 0;
	c.facing = UNIT_COMMAND_BUILD_NO_FACING;
	c.unitId = unit->GetUnitId();

	int e = callback->GetEngine()->HandleCommand(callback->GetTeamId(),-1,COMMAND_UNIT_BUILD,&c);
	return (e == 0);
}

bool CSpringUnit::Reclaim(IMapFeature* mapFeature){
	SReclaimUnitCommand c;
	c.unitId = this->unit->GetUnitId();
	c.toReclaimUnitIdOrFeatureId = mapFeature->ID();
	
	int e = callback->GetEngine()->HandleCommand(callback->GetTeamId(),-1,COMMAND_UNIT_RECLAIM,&c);
	return (e == 0);
}

bool CSpringUnit::AreaReclaim(Position p, double radius){
	SReclaimAreaUnitCommand c;
	c.unitId = this->unit->GetUnitId();
	c.radius = radius;
	SAIFloat3 pos;
	pos.x = p.x;
	pos.y = p.y;
	pos.z = p.z;
	c.pos = pos;
	
	int e = callback->GetEngine()->HandleCommand(callback->GetTeamId(),-1,COMMAND_UNIT_RECLAIM_AREA,&c);
	return (e == 0);
}

bool CSpringUnit::Reclaim(IUnit* unit){
	SReclaimUnitCommand c;
	c.unitId = this->unit->GetUnitId();
	c.toReclaimUnitIdOrFeatureId = unit->ID();
	
	int e = callback->GetEngine()->HandleCommand(callback->GetTeamId(),-1,COMMAND_UNIT_RECLAIM,&c);
	return (e == 0);
}

bool CSpringUnit::Attack(IUnit* unit){
	SAttackUnitCommand c;
	c.toAttackUnitId = unit->ID();
	c.unitId = this->unit->GetUnitId();
	
	int e = callback->GetEngine()->HandleCommand(callback->GetTeamId(),-1,COMMAND_UNIT_ATTACK,&c);
	return (e == 0);
}

bool CSpringUnit::Repair(IUnit* unit){
	SRepairUnitCommand c;
	c.toRepairUnitId = unit->ID();
	c.unitId = this->unit->GetUnitId();
	int e = callback->GetEngine()->HandleCommand(callback->GetTeamId(),-1,COMMAND_UNIT_REPAIR,&c);
	return (e == 0);
}

Position CSpringUnit::GetPosition(){
	Position p;
	SAIFloat3 f = unit->GetPos();
	p.x = f.x;
	p.y = f.y;
	p.z = f.z;
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
	springai::Resource* r = springai::Resource::GetInstance(callback,idx);
	SResourceTransfer rt;
	rt.consumption = this->unit->GetResourceUse(*r);
	rt.generation = this->unit->GetResourceMake(*r);
	rt.rate = 1;
	rt.resource = game->GetResource(idx);
	rt.gameframe = game->Frame();
	return rt;
}
