#ifndef IGAME_H
#define IGAME_H

#include <string>
#include <vector>

#include "api.h"

class IGame {
public:
	virtual ~IGame(){}
	virtual void SendToConsole(std::string message)=0;
	virtual int Frame()=0;
	virtual bool IsPaused()=0;

	virtual IMap* Map()=0;

	//virtual std::string GameID()=0;

	virtual IUnitType* GetTypeByName(std::string typeName)=0;

	virtual const char* ConfigFolderPath()=0;
	virtual std::string ReadFile(std::string filename)=0;
	virtual bool LocatePath(std::string& filename)=0;

	virtual int GetTeamID()=0;
	virtual bool HasEnemies()=0;
	virtual bool HasFriendlies()=0;
	virtual std::vector<IUnit*> GetEnemies()=0;
	virtual std::vector<IUnit*> GetFriendlies()=0;
	virtual std::vector<IUnit*> GetUnits()=0;

	virtual std::string GameName()=0;

	virtual bool FileExists(std::string filename)=0;

	virtual void AddMarker(Position p,std::string label)=0;

	virtual std::string SendToContent(std::string data)=0;

	virtual SResourceData GetResource(int idx)=0;
	virtual int GetResourceCount()=0;
	virtual SResourceData GetResourceByName(std::string name)=0;

	virtual IAI* Me()=0;

	virtual IUnit* getUnitByID( int unit_id )=0;
};

#endif
