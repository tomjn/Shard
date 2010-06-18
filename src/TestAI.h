#pragma once

#include "API/interfaces/IGame.h"
#include "API/interfaces/IAI.h"
#include <vector>
#include <map>

extern "C" {
	#include "lua.h"
	#include "lualib.h"
	#include "lauxlib.h"
}
#include "API/swig.h"

class CTestAI : public IAI {
public:
	
	CTestAI(IGame* game);
	virtual ~CTestAI();

	virtual void Init();
	virtual void Update();
	virtual void GameEnd();

	virtual void UnitCreated(IUnit* unit);
	virtual void UnitBuilt(IUnit* unit);
	virtual void UnitDead(IUnit* unit);
	virtual void UnitIdle(IUnit* unit);

	virtual void UnitDamaged(IUnit* unit, IUnit* attacker);
	
	lua_State *L;

	void PushIUnit(IUnit* unit);

	static IAI* ai;
protected:

	swig_type_info* unittype;
	void LoadLuaFile(std::string filename);
	IGame* game;
	
};
