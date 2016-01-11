#pragma once

class CSpringGame;

#include "../../TestAI.h"
#include "SpringMap.h"
#include "SpringUnit.h"
#include "SpringUnitType.h"
#include "SpringMapFeature.h"

class CSpringGame : public IGame {
public:
	CSpringGame(springai::OOAICallback* callback);
	virtual ~CSpringGame();

	virtual IMap* Map() override;

	virtual std::string GameID();
	virtual void SendToConsole(std::string message) override;
	virtual int Frame() override;
	virtual bool IsPaused() override;

	virtual IUnitType* GetTypeByName(std::string typeName) override;

	virtual const char* ConfigFolderPath() override;
	virtual std::string ReadFile(std::string filename) override;
	virtual bool LocatePath(std::string& filename) override;

	virtual int GetTeamID() override;

	virtual bool HasEnemies() override;
	virtual bool HasFriendlies() override;
	virtual std::vector<IUnit*> GetEnemies() override;
	virtual std::vector<IUnit*> GetFriendlies() override;
	virtual std::vector<IUnit*> GetUnits() override;

	virtual CSpringUnit* CreateUnit(int id);
	virtual CSpringUnit* CreateUnit(springai::Unit* unit, bool addToVectors = true);
	virtual void DestroyUnit(int id);
	virtual CSpringUnit* GetUnitById(int id);

	virtual IAI* Me() override;

	virtual std::string GameName() override;

	virtual bool FileExists(std::string filename) override;

	virtual void AddMarker(Position p,std::string label) override;

	virtual std::string SendToContent(std::string data) override;


	virtual SResourceData GetResource(int idx) override;
	virtual int GetResourceCount() override;
	virtual SResourceData GetResourceByName(std::string name) override;

	IUnitType* ToIUnitType(springai::UnitDef* def);

	virtual void UpdateUnits();

	virtual IUnit* getUnitByID( int unit_id ) override;
	/*virtual void removeUnit( IUnit* dead_unit );*/
protected:
	//helper functions to managing unit vectors.
	//vectors are updated at maximum once per frame.
	//if unit vectors are required, best call "UpdateUnits" before.
	virtual void FillUnitVector(std::vector<IUnit*>& target, std::vector<springai::Unit*> source);

	CSpringMap* map;
	springai::OOAICallback* callback;
	CTestAI* ai;
	std::map<std::string,CSpringUnitType*> definitions;
	springai::DataDirs* datadirs;
	springai::Economy* economy;
	std::vector<springai::Resource*> resources;
	springai::Game* game;
	std::map<int,CSpringUnit*> aliveUnits;
	std::vector<IUnit*> friendlyUnits;
	std::vector<IUnit*> teamUnits;
	std::vector<IUnit*> enemyUnits;
	int lastUnitUpdate;
};
