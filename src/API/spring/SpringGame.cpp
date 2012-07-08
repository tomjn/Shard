
#include <iterator>
#include <iostream>
#include <fstream>
#include <stdlib.h>

#include "spring_api.h"
#include "AI/Wrappers/Cpp/src-generated/SkirmishAI.h"

CSpringGame::CSpringGame(springai::OOAICallback* callback)
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
	map = new CSpringMap(callback,this);

}

CSpringGame::~CSpringGame(){
	delete ai;
	delete map;
}

IMap* CSpringGame::Map(){
	return map;
}


std::string CSpringGame::GameID(){
	return "";//callback->;
}

void CSpringGame::SendToConsole(std::string message){
	callback->GetGame()->SendTextMessage(message.c_str(), 0);
}

int CSpringGame::Frame(){
	return callback->GetGame()->GetCurrentFrame();
}

bool CSpringGame::IsPaused(){
	return callback->GetGame()->IsPaused();
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

IAI* CSpringGame::Me(){
	return ai;
}

std::string CSpringGame::GameName(){
	return callback->GetMod()->GetShortName();
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
	const bool located = callback->GetDataDirs()->LocatePath(absPath, absPath_sizeMax, filename.c_str(), false /*writable*/, false /*create*/, dir, false /*common*/);
	if (located){
		filename=absPath;
	}
	return located;
}

void CSpringGame::AddMarker(Position p,std::string label){
	const springai::AIFloat3 pos(p.x, p.y, p.z);
	callback->GetMap()->GetDrawer()->AddPoint(pos, label.c_str());
}

std::string CSpringGame::SendToContent(std::string data){
	return callback->GetLua()->CallRules(data.c_str(), -1);
}



IUnitType* CSpringGame::ToIUnitType(springai::UnitDef* def){
	if(def){
		std::string name = def->GetName();
		return GetTypeByName(name);
	}else{
		return NULL;
	}
}

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

int CSpringGame::GetTeamID(){
	return callback->GetSkirmishAI()->GetTeamId();
}

std::vector<IUnit*> CSpringGame::GetUnits(){
	std::vector<IUnit*> friendliesv;
	
	std::vector<springai::Unit*> friendlies = callback->GetTeamUnits();
	std::vector<springai::Unit*>::iterator i = friendlies.begin();
	for(;i != friendlies.end(); ++i){
		CSpringUnit* unit = new CSpringUnit(callback,*i,this);
		friendliesv.push_back(unit);
	}
	return friendliesv;
}


SResourceData CSpringGame::GetResource(int idx){
	SResourceData res;
	std::vector<springai::Resource*> resources = callback->GetResources();
	if(!resources.empty()){

		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			if(r->GetResourceId() == idx){
				res.id = r->GetResourceId();
				res.name = r->GetName();
				res.gameframe = this->Frame();
				res.income = callback->GetEconomy()->GetIncome(r);
				res.usage = callback->GetEconomy()->GetUsage(r);
				res.capacity = callback->GetEconomy()->GetStorage(r);
				res.reserves = callback->GetEconomy()->GetCurrent(r);
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

SResourceData CSpringGame::GetResourceByName(std::string name){
	SResourceData res;
	std::vector<springai::Resource*> resources = callback->GetResources();
	if(!resources.empty()){

		std::vector<springai::Resource*>::iterator i = resources.begin();
		for(;i != resources.end();++i){
			springai::Resource* r = *i;
			std::string rname = r->GetName();
			if(rname == name){
				res.name = rname;
				res.id = r->GetResourceId();
				res.gameframe = this->Frame();
				res.income = callback->GetEconomy()->GetIncome(r);
				res.usage = callback->GetEconomy()->GetUsage(r);
				res.capacity = callback->GetEconomy()->GetStorage(r);
				res.reserves = callback->GetEconomy()->GetCurrent(r);
				return res;
				break;
			}
		}
	}
	return res;
}
