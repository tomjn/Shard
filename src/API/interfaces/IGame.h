#ifndef IGAME_H
#define IGAME_H

#include <string>
#include <vector>
#include "IAI.h"
#include "Resource.h"
#include "ResourceUsage.h"
extern "C" {
	#include "lua.h"
	#include "lualib.h"
	#include "lauxlib.h"
}
class IUnit;
class IMapFeature;

class IGame {
public:
	virtual void SendToConsole(std::string message)=0;
	virtual int Frame()=0;
	virtual bool IsPaused()=0;

	//virtual std::string GameID()=0;

	virtual Position FindClosestBuildSite(IUnitType* t, Position builderPos, double searchRadius, double minimumDistance)=0;
	virtual bool CanBuildHere(IUnitType* t, Position pos)=0;

	virtual IUnitType* GetTypeByName(std::string typeName)=0;

	virtual const char* ConfigFolderPath()=0;
	virtual std::string ReadFile(std::string filename)=0;
	virtual void ExecuteFile(std::string filename)=0;

	virtual std::vector<IUnit*> GetEnemies()=0;

	//virtual int Test()=0;
	virtual int Test(lua_State* L)=0;

	virtual std::vector<IUnit*> GetFriendlies()=0;
	
	virtual std::vector<IMapFeature*> GetMapFeatures()=0;
	virtual std::vector<IMapFeature*> GetMapFeatures(Position p, double radius)=0;

	virtual int SpotCount()=0;
	virtual Position GetSpot(int idx)=0;
	virtual std::vector<Position>& GetMetalSpots()=0;

	virtual Position MapDimensions()=0;

	virtual std::string GameName()=0;
	virtual std::string MapName()=0;

	virtual bool FileExists(std::string filename)=0;

	virtual void AddMarker(Position p,std::string label)=0;

	virtual std::string SendToContent(std::string data)=0;

	virtual double AverageWind()=0;
	virtual double MinimumWindSpeed()=0;
	virtual double MaximumWindSpeed()=0;

	virtual double TidalStrength()=0;


	virtual SResource GetResource(int idx)=0;
	virtual int GetResourceCount()=0;
	virtual SResource GetResource(std::string name)=0;

	virtual IAI* Me()=0;
};

#endif
