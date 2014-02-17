#pragma once

class CSpringGame;

#include "../../TestAI.h"
#include "SpringMap.h"
#include "SpringUnitType.h"
#include "SpringMapFeature.h"

class CSpringGame : public IGame {
public:
	CSpringGame(springai::OOAICallback* callback);
	virtual ~CSpringGame();

	virtual IMap* Map();

	virtual std::string GameID();
	virtual void SendToConsole(std::string message);
	virtual int Frame();
	virtual bool IsPaused();

	virtual IUnitType* GetTypeByName(std::string typeName);

	virtual const char* ConfigFolderPath();
	virtual std::string ReadFile(std::string filename);
	virtual bool LocatePath(std::string& filename);

	virtual int GetTeamID();

	virtual bool HasEnemies();
	virtual bool HasFriendlies();
	virtual std::vector<IUnit*> GetEnemies();
	virtual std::vector<IUnit*> GetFriendlies();
	virtual std::vector<IUnit*> GetUnits();


	virtual IAI* Me();

	virtual std::string GameName();

	virtual bool FileExists(std::string filename);

	virtual void AddMarker(Position p,std::string label);

	virtual std::string SendToContent(std::string data);


	virtual SResourceData GetResource(int idx);
	virtual int GetResourceCount();
	virtual SResourceData GetResourceByName(std::string name);

	IUnitType* ToIUnitType(springai::UnitDef* def);

	virtual IUnit* getUnitByID( int unit_id );
	/*virtual void removeUnit( IUnit* dead_unit );*/
protected:
	//helper functions to managing unit vectors.
	//vectors are updated at maximum once per frame.
	//if unit vectors are required, best call "UpdateUnits" before.
	virtual void FillUnitVector(std::vector<IUnit*> target, std::vector<springai::Unit*> source);
	virtual void UpdateUnits();

	CSpringMap* map;
	springai::OOAICallback* callback;
	CTestAI* ai;
	std::map<std::string,CSpringUnitType*> definitions;
	springai::DataDirs* datadirs;
	springai::Economy* economy;
	std::vector<springai::Resource*> resources;
	springai::Game* game;
	std::vector<IUnit*> friendlyUnits;
	std::vector<IUnit*> teamUnits;
	std::vector<IUnit*> enemyUnits;
	int lastUnitUpdate;
};
