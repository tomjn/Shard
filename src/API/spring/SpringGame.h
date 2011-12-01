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
protected:

	CSpringMap* map;
	springai::OOAICallback* callback;
	CTestAI* ai;
	std::map<std::string,CSpringUnitType*> definitions;
};
