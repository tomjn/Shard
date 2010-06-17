#pragma once

class CSpringGame;

extern "C" {
	#include "lua.h"
	#include "lualib.h"
	#include "lauxlib.h"
}

#include "../interfaces/api.h"
#include <map>
#include "../../TestAI.h"
#include "AICallback.h"
#include "Resource.h"
#include "SpringUnitType.h"
#include "SpringMapFeature.h"

class CSpringGame : public IGame {
public:
	CSpringGame(springai::AICallback* callback);
	virtual ~CSpringGame();

	virtual std::string GameID();
	virtual void SendToConsole(std::string message);
	virtual int Frame();
	virtual bool IsPaused();

	virtual Position FindClosestBuildSite(IUnitType* t, Position builderPos, double searchRadius, double minimumDistance);
	virtual bool CanBuildHere(IUnitType* t, Position pos);

	virtual IUnitType* GetTypeByName(std::string typeName);
	
	virtual const char* ConfigFolderPath();
	virtual std::string ReadFile(std::string filename);
	int report (int status);
	virtual void ExecuteFile(std::string filename);

	IUnitType* ToIUnitType(springai::UnitDef* def);

	//virtual void GetEnemiesLua();
	virtual std::vector<IUnit*> GetEnemies();

	virtual int Test();
	virtual int Test(lua_State* L);

	virtual std::vector<IUnit*> GetFriendlies();
	
	virtual std::vector<IMapFeature*> GetMapFeatures();
	virtual std::vector<IMapFeature*> GetMapFeatures(Position p, double radius);


	virtual IAI* Me();

	virtual int SpotCount();
	virtual Position GetSpot(int idx);
	virtual std::vector<Position>& GetMetalSpots();

	virtual Position MapDimensions();

	virtual std::string GameName();
	virtual std::string MapName();

	virtual bool FileExists(std::string filename);
	
	virtual void AddMarker(Position p,std::string label);

	virtual std::string SendToContent(std::string data);

	virtual double AverageWind();

	virtual double MinimumWindSpeed();
	virtual double MaximumWindSpeed();

	virtual double TidalStrength();


	springai::Resource* GetMetalResource();

	virtual SResource GetResource(int idx);
	virtual int GetResourceCount();
	virtual SResource GetResource(std::string name);
protected:
	springai::Resource* metal;
	springai::AICallback* callback;
	CTestAI* ai;

	std::vector<Position> metalspots;

	std::map<std::string,CSpringUnitType*> definitions;
};
