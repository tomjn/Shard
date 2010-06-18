#include "SpringGame.h"
#include "SpringUnitType.h"
#include "SpringUnit.h"
#include "ExternalAI/Interface/AISEvents.h"
#include "ExternalAI/Interface/AISCommands.h"

#include <iterator>
#include <iostream>
#include <fstream>
#include <stdlib.h>

#include "Unit.h"
#include "UnitDef.h"
#include "Engine.h"
#include "DataDirs.h"
#include "Map.h"
#include "Mod.h"
#include "Game.h"
#include "Cheats.h"
#include "Economy.h"


int lua_epcall(lua_State *L, int nargs);

CSpringGame::CSpringGame(springai::AICallback* callback)
: callback(callback){
	ai = new CTestAI(this);
	callback->GetCheats()->SetEnabled(true);

	std::vector<springai::UnitDef*> defs = callback->GetUnitDefs();
	if(!defs.empty()){
		std::vector<springai::UnitDef*>::iterator i = defs.begin();
		for(;i!=defs.end();++i){
			springai::UnitDef* u = *i;
			std::string name = u->GetName();
			CSpringUnitType* udef = new CSpringUnitType(this,callback,u);
			definitions[name] = udef;
		}
	}
	metal = NULL;
	std::vector<springai::Resource*> resources = callback->GetResources();
	if(!resources.empty()){

		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			std::string name = r->GetName();
			if(name == "Metal"){
				this->metal = r;
				break;
			}
		}
	}

	if(metal){
		std::vector<SAIFloat3> positions = callback->GetMap()->GetResourceMapSpotsPositions(*metal,0);
		if(!positions.empty()){
			std::vector<SAIFloat3>::iterator j = positions.begin();
			for(;j != positions.end();++j){
				Position p;
				p.x = j->x;
				p.y = j->y;
				p.z = j->z;
				metalspots.push_back(p);
			}
		}
	}

}

CSpringGame::~CSpringGame(){
	delete ai;
}

std::string CSpringGame::GameID(){
	return "";//callback->;
}

void CSpringGame::SendToConsole(std::string message){
	
	SSendTextMessageCommand cmd;
	cmd.text = message.c_str();
	cmd.zone = 0;
	callback->GetEngine()->HandleCommand(0, -1, COMMAND_SEND_TEXT_MESSAGE, &cmd);
}

int CSpringGame::Frame(){
	return callback->GetGame()->GetCurrentFrame();
}

bool CSpringGame::IsPaused(){
	return callback->GetGame()->IsPaused();
}

Position CSpringGame::FindClosestBuildSite(IUnitType* t, Position builderPos, double searchRadius, double minimumDistance){
	CSpringUnitType* ut = (CSpringUnitType*)t;
	SAIFloat3 p;
	p.x = builderPos.x;
	p.y = builderPos.y;
	p.z = builderPos.z;
	p = callback->GetMap()->FindClosestBuildSite(*(ut->GetUnitDef()),p,searchRadius,minimumDistance,0);
	Position pos;
	pos.x = p.x;
	pos.y = p.y;
	pos.z = p.z;
	return pos;
}

bool CSpringGame::CanBuildHere(IUnitType* t, Position pos){
	CSpringUnitType* ut = (CSpringUnitType*)t;
	SAIFloat3 p;
	p.x = pos.x;
	p.y = pos.y;
	p.z = pos.z;
	return callback->GetMap()->IsPossibleToBuildAt(*(ut->GetUnitDef()),p,UNIT_COMMAND_BUILD_NO_FACING);
}

IUnitType* CSpringGame::GetTypeByName(std::string typeName){
	std::map<std::string,CSpringUnitType*>::iterator i = definitions.find(typeName);
	if(i != definitions.end()){
		return i->second;
	}else{
		return 0;
	}
}

const char* CSpringGame::ConfigFolderPath(){
	return callback->GetDataDirs()->GetConfigDir();
}

std::string CSpringGame::ReadFile(std::string filename){

	std::ifstream InFile( filename.c_str());
	if( !InFile ) {
		//cerr << "Couldn´t open input file" << endl;
		return "";
	}
	
	std::string s ="";

	// create reader objects
	std::istream_iterator<std::string> DataBegin( InFile );
	std::istream_iterator<std::string> DataEnd;

	while( DataBegin != DataEnd ) {
		s += *DataBegin;
		DataBegin++;
	}
	return s;
}

int CSpringGame::report (int status) {
	const char *msg;
	if (status) {
		msg = lua_tostring(ai->L, -1);
		if (msg == NULL){
			msg = "(error with no message)";
		}
		std::string ermsg = "status=";
		ermsg += status;
		ermsg += std::string(", ");
		ermsg += msg;
		SendToConsole(ermsg);
		//fprintf(stderr, "status=%d, %s\n", status, msg);
		lua_pop(ai->L, 1);
	}
	return status;
}

void CSpringGame::ExecuteFile(std::string filename){
	std::string f = ConfigFolderPath();
	f += "\\ai\\";
	f += filename;
	int err = luaL_loadfile (ai->L, f.c_str());
	if (err == 0){
		int status = lua_epcall(ai->L, 0);
		if (status == 0){
			
		}
	}else{
		SendToConsole("failed to load in: " + f);
		report(err);
	}
}

IAI* CSpringGame::Me(){
	return ai;
}

int CSpringGame::SpotCount(){
	return metalspots.size();
}

Position CSpringGame::GetSpot(int idx){
	return metalspots[idx];
}

std::vector<Position>& CSpringGame::GetMetalSpots(){
	return metalspots;
}

Position CSpringGame::MapDimensions(){
	
	Position p;
	p.x = callback->GetMap()->GetWidth();
	p.z = callback->GetMap()->GetHeight();
	
	return p;
}

std::string CSpringGame::GameName(){
	return callback->GetMod()->GetShortName();
}

std::string CSpringGame::MapName(){
	return callback->GetMap()->GetName();
}

bool CSpringGame::FileExists(std::string filename){
	filename = ConfigFolderPath() + std::string("\\ai\\")+filename;
	std::ifstream InFile( filename.c_str());
	bool r = InFile.is_open();
	if(r){
		InFile.close();
	}
	return r;
}

void CSpringGame::AddMarker(Position p,std::string label){
	SAddPointDrawCommand c;
	c.pos.x = p.x;
	c.pos.z = p.z;

	c.label = label.c_str();
	callback->GetEngine()->HandleCommand(callback->GetTeamId(),-1,COMMAND_UNIT_BUILD,&c);
}

std::string CSpringGame::SendToContent(std::string data){
	SCallLuaRulesCommand c;
	c.data = data.c_str();
	c.inSize = -1;
	callback->GetEngine()->HandleCommand(callback->GetTeamId(),-1,COMMAND_CALL_LUA_RULES,&c);
	std::string returndata = c.ret_outData;
	return returndata;
}

double CSpringGame::AverageWind(){
	float minwind = callback->GetMap()->GetMinWind();
	float maxwind = callback->GetMap()->GetMaxWind();
	return (minwind+maxwind)/2;
}

double CSpringGame::MinimumWindSpeed(){
	return callback->GetMap()->GetMinWind();
}

double CSpringGame::MaximumWindSpeed(){
	return callback->GetMap()->GetMaxWind();
}

double CSpringGame::TidalStrength(){
	return callback->GetMap()->GetTidalStrength();
}

IUnitType* CSpringGame::ToIUnitType(springai::UnitDef* def){
	std::string name = def->GetName();
	return GetTypeByName(name);
}

/*void CSpringGame::GetEnemiesLua(){
	std::vector<springai::Unit*> enemies = callback->GetEnemyUnits();
	if( enemies.empty()){
		lua_pushnil(ai->L);
		return;
	} else{
		lua_newtable(ai->L);
		int top = lua_gettop(ai->L);
		int index = 1;

		for (std::vector<springai::Unit*>::iterator it = enemies.begin(); it != enemies.end(); ++it) {
			//const char* key = it->first.c_str();
			//const char* value = it->second.c_str();
			
			//key
			lua_pushinteger(ai->L,index);//lua_pushstring(L, key);

			//value
			CSpringUnit* unit = new CSpringUnit(callback,*it,this);
			ai->PushIUnit(unit);
			//lua_pushstring(ai->L, value);
			lua_settable(ai->L, -3);
			++index;
		}
		::lua_pushvalue(ai->L,-1);
		/*lua_createtable(ai->L, enemies.size(), 0);
		int newTable = lua_gettop(ai->L);
		
		std::vector<springai::Unit*>::const_iterator iter = enemies.begin();
		while(iter != enemies.end()) {
			CSpringUnit* unit = new CSpringUnit(callback,*iter,this);
			ai->PushIUnit(unit);
			//lua_pushstring(L, (*iter).c_str());
			lua_rawseti(ai->L, newTable, index);
			++iter;
			++index;
		}*//*
	}
}*/
std::vector<IUnit*> CSpringGame::GetEnemies(){
	std::vector<IUnit*> enemiesv;
	
	std::vector<springai::Unit*> enemies = callback->GetEnemyUnits();
	std::vector<springai::Unit*>::iterator i = enemies.begin();
	for(;i != enemies.end(); ++i){
		CSpringUnit* unit = new CSpringUnit(callback,*i,this);
		enemiesv.push_back(unit);
	}
	return enemiesv;
}


int CSpringGame::Test(){
	return 1;
}

int CSpringGame::Test(lua_State* L){
	return 5;
}

std::vector<IUnit*> CSpringGame::GetFriendlies(){
	std::vector<IUnit*> friendliesv;
	
	std::vector<springai::Unit*> friendlies = callback->GetFriendlyUnits();
	std::vector<springai::Unit*>::iterator i = friendlies.begin();
	for(;i != friendlies.end(); ++i){
		CSpringUnit* unit = new CSpringUnit(callback,*i,this);
		friendliesv.push_back(unit);
	}
	return friendliesv;
}
 
std::vector<IMapFeature*> CSpringGame::GetMapFeatures(){
	std::vector< IMapFeature*> mapFeatures;
	
	std::vector<springai::Feature*> features = callback->GetFeatures();
	std::vector<springai::Feature*>::iterator i = features.begin();
	for(;i != features.end(); ++i){
		CSpringMapFeature* f = new CSpringMapFeature(callback,*i,this);
		mapFeatures.push_back(f);
	}
	return mapFeatures;
}

std::vector<IMapFeature*> CSpringGame::GetMapFeatures(Position p, double radius){
	SAIFloat3 pos;
	pos.x = p.x;
	pos.y = p.y;
	pos.z = p.z;
	std::vector< IMapFeature*> mapFeatures;
	
	std::vector<springai::Feature*> features = callback->GetFeaturesIn(pos,radius);
	std::vector<springai::Feature*>::iterator i = features.begin();
	for(;i != features.end(); ++i){
		CSpringMapFeature* f = new CSpringMapFeature(callback,*i,this);
		mapFeatures.push_back(f);
	}
	return mapFeatures;
}

springai::Resource* CSpringGame::GetMetalResource(){
	return metal;
}


SResource CSpringGame::GetResource(int idx){
	SResource res;
	std::vector<springai::Resource*> resources = callback->GetResources();
	if(!resources.empty()){

		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			if(r->GetResourceId() == idx){
				SResource res;
				res.name = r->GetName();;
				res.gameframe = this->Frame();
				res.income = callback->GetEconomy()->GetIncome(*r);
				res.usage = callback->GetEconomy()->GetUsage(*r);
				res.capacity = callback->GetEconomy()->GetStorage(*r);
				res.reserves = callback->GetEconomy()->GetCurrent(*r);
				return res;
				break;
			}
		}
	}
	return res;
}

int CSpringGame::GetResourceCount(){
	std::vector<springai::Resource*> resources = callback->GetResources();
	if(resources.empty()){
		return 0;
	}else{
		return resources.size();
	}

}

SResource CSpringGame::GetResource(std::string name){
	std::vector<springai::Resource*> resources = callback->GetResources();
	if(!resources.empty()){

		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			std::string rname = r->GetName();
			if(rname == name){
				SResource res;
				res.name = rname;
				res.gameframe = this->Frame();
				res.income = callback->GetEconomy()->GetIncome(*r);
				res.usage = callback->GetEconomy()->GetUsage(*r);
				res.capacity = callback->GetEconomy()->GetStorage(*r);
				res.reserves = callback->GetEconomy()->GetCurrent(*r);
				return res;
				break;
			}
		}
	}
}
