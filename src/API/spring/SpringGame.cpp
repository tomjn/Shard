#include <iterator>
#include <iostream>
#include <fstream>
#include <stdlib.h>

#include "spring_api.h"
#include "AI/Wrappers/Cpp/src-generated/SkirmishAI.h"
#include "AI/Wrappers/Cpp/src-generated/WrappUnit.h"

CSpringGame::CSpringGame(springai::OOAICallback* callback)
: callback(callback), datadirs(callback->GetDataDirs()),
  economy(callback->GetEconomy()), resources(callback->GetResources()),
  game(callback->GetGame()), lastUnitUpdate(-1) {
	ai = new CTestAI(this);
	springai::Cheats* cheat = callback->GetCheats();
	cheat->SetEnabled(true);
	delete cheat;

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
	map = new CSpringMap(callback,this);

}

CSpringGame::~CSpringGame(){
	delete ai;
	delete map;
	std::map<std::string,CSpringUnitType*>::iterator iter = definitions.begin();
	while(iter != definitions.end()) {
		delete iter->second;
		++iter;
	}
	for (int i = 0; i < resources.size(); i += 1) {
		delete resources[i];
	}
	delete datadirs;
	delete economy;
	delete game;
	for (std::map<int, CSpringUnit*>::iterator i = aliveUnits.begin(); i != aliveUnits.end(); ++i) {
		delete i->second;
	}
}

IMap* CSpringGame::Map(){
	return map;
}


std::string CSpringGame::GameID(){
	return "";//callback->;
}

void CSpringGame::SendToConsole(std::string message){
	game->SendTextMessage(message.c_str(), 0);
}

int CSpringGame::Frame(){
	return game->GetCurrentFrame();
}

bool CSpringGame::IsPaused(){
	return game->IsPaused();
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
	return datadirs->GetConfigDir();
}

std::string CSpringGame::ReadFile(std::string filename){

	std::ifstream InFile( filename.c_str());
	if( !InFile ) {
		//cerr << "Couldn't open input file" << endl;
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

IAI* CSpringGame::Me(){
	return ai;
}

std::string CSpringGame::GameName(){
	springai::Mod* mod = callback->GetMod();
	std::string name = mod->GetShortName();
	delete mod;
	return name;
}



bool CSpringGame::FileExists(std::string filename){
	filename = ConfigFolderPath() + std::string("/ai/")+filename;
	std::ifstream InFile( filename.c_str());
	bool r = InFile.is_open();
	if(r){
		InFile.close();
	}
	return r;
}

bool CSpringGame::LocatePath(std::string& filename){
	static const size_t absPath_sizeMax = 2048;
	char absPath[absPath_sizeMax];
	const bool dir = !filename.empty() && (*filename.rbegin() == '/' || *filename.rbegin() == '\\');
	const bool located = datadirs->LocatePath(absPath, absPath_sizeMax, filename.c_str(), false /*writable*/, false /*create*/, dir, false /*common*/);
	if (located){
		filename=absPath;
	}
	return located;
}

void CSpringGame::AddMarker(Position p,std::string label){
	const springai::AIFloat3 pos(p.x, p.y, p.z);
	springai::Map* map = callback->GetMap();
	springai::Drawer* drawer = map->GetDrawer();
	drawer->AddPoint(pos, label.c_str());
	delete drawer;
	delete map;
}

std::string CSpringGame::SendToContent(std::string data){
	springai::Lua* lua = callback->GetLua();
	std::string res = lua->CallRules(data.c_str(), -1);
	delete lua;
	return res;
}



IUnitType* CSpringGame::ToIUnitType(springai::UnitDef* def){
	if(def){
		std::string name = def->GetName();
		return GetTypeByName(name);
	}else{
		return NULL;
	}
}

CSpringUnit* CSpringGame::CreateUnit(int id) {
	if (id < 0) {
		SendToConsole("shard-runtime warning: tried to create unit with id < 0");
		return NULL;
	}
	springai::Unit* unit = springai::WrappUnit::GetInstance(callback->GetSkirmishAIId(), id);
	if (unit) {
		return CreateUnit(unit);
	} else {
		SendToConsole("shard-runtime warning: Could not create unit, WrappUnit returned NULL.");
		return NULL;
	}
}


CSpringUnit* CSpringGame::CreateUnit(springai::Unit* unit, bool addToVectors) {
	std::map<int, CSpringUnit*>::iterator i = aliveUnits.find(unit->GetUnitId());
	if (i == aliveUnits.end()) {
		CSpringUnit* u = new CSpringUnit(callback, unit, this);
		aliveUnits[unit->GetUnitId()] = u;

		if (addToVectors) {
			if (u->Team() == GetTeamID()) {
				teamUnits.push_back(u);
				friendlyUnits.push_back(u);
			} else if (u->IsAlly(game->GetMyAllyTeam())) {
				friendlyUnits.push_back(u);
			} else {
				enemyUnits.push_back(u);
			}
		}

		return u;
	} else {
		delete unit;
		return i->second;
	}
}

void CSpringGame::DestroyUnit(int id) {
	CSpringUnit* u = GetUnitById(id);
	if (u) {
		u->SetDead(true);
	}
}

CSpringUnit* CSpringGame::GetUnitById(int id) {
	if (id < 0) {
		return NULL;
	}

	std::map<int, CSpringUnit*>::iterator i = aliveUnits.find(id);
	if (i == aliveUnits.end()) {
		return NULL;
	} else {
		return i->second;
	}
}

void CSpringGame::FillUnitVector(std::vector<IUnit*>& target, std::vector<springai::Unit*> source)
{
	target.clear();

	std::vector<springai::Unit*>::iterator i = source.begin();
	for(;i != source.end(); ++i){
		if (!(*i)) {
			continue;
		}

		CSpringUnit* unit = GetUnitById((*i)->GetUnitId());
		if (!unit) {
			unit = CreateUnit(*i, false);
		} else {
			delete (*i);
		}

		if (unit) {
			target.push_back(unit);
		}
	}
}

void CSpringGame::UpdateUnits()
{
	if (lastUnitUpdate < Frame())
	{

		FillUnitVector(enemyUnits, callback->GetEnemyUnits()); //events about enemy unit seem to not reach us.
		FillUnitVector(friendlyUnits, callback->GetFriendlyUnits());
		FillUnitVector(teamUnits, callback->GetTeamUnits());

		lastUnitUpdate = Frame();
	}
}

bool CSpringGame::HasEnemies(){
	UpdateUnits();
	return !enemyUnits.empty();
}

std::vector<IUnit*> CSpringGame::GetEnemies(){
	UpdateUnits();
	return enemyUnits;
}

bool CSpringGame::HasFriendlies(){
	UpdateUnits();
	return !friendlyUnits.empty();
}

std::vector<IUnit*> CSpringGame::GetFriendlies(){
	UpdateUnits();
	return friendlyUnits;
}

int CSpringGame::GetTeamID(){
	springai::SkirmishAI* ai = callback->GetSkirmishAI();
	int id = ai->GetTeamId();
	delete ai;
	return id;
}

std::vector<IUnit*> CSpringGame::GetUnits(){
	UpdateUnits();
	return teamUnits;
}


SResourceData CSpringGame::GetResource(int idx){
	SResourceData res;
	if(!resources.empty()){
		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			if(r->GetResourceId() == idx){
				res.id = r->GetResourceId();
				res.name = r->GetName();
				res.gameframe = this->Frame();
				res.income = economy->GetIncome(r);
				res.usage = economy->GetUsage(r);
				res.capacity = economy->GetStorage(r);
				res.reserves = economy->GetCurrent(r);
				return res;
			}
		}
	}
	return res;
}

int CSpringGame::GetResourceCount(){
	if(resources.empty()){
		return 0;
	}else{
		return resources.size();
	}

}

SResourceData CSpringGame::GetResourceByName(std::string name){
	SResourceData res;
	if(!resources.empty()){
		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			std::string rname = r->GetName();
			if(rname == name){
				res.name = rname;
				res.id = r->GetResourceId();
				res.gameframe = this->Frame();
				res.income = economy->GetIncome(r);
				res.usage = economy->GetUsage(r);
				res.capacity = economy->GetStorage(r);
				res.reserves = economy->GetCurrent(r);
				return res;
			}
		}
	}
	return res;
}

IUnit* CSpringGame::getUnitByID( int unit_id ) {
	return ai->GetGame()->getUnitByID( unit_id );
}

/*void CSpringGame::removeUnit( IUnit* dead_unit ) {
	std::map<int, CSpringUnit* >::iterator i = aliveUnits.find(evt->unit);
	if(i != aliveUnits.end()){
		CSpringUnit* u = i->second;
		game->Me()->UnitDead(u);
		aliveUnits.erase(i);
		delete u;
	}
}*/
