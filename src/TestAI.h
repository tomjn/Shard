#pragma once

#include "API/interfaces/api.h"


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
	virtual void GameMessage(const char* text);

	virtual void UnitCreated(IUnit* unit);
	virtual void UnitBuilt(IUnit* unit);
	virtual void UnitDead(IUnit* unit);
	virtual void UnitIdle(IUnit* unit);
	virtual void UnitMoveFailed(IUnit* unit);

	virtual void UnitGiven(IUnit* unit);

	virtual void UnitDamaged(IUnit* unit, IUnit* attacker, IDamage::Ptr damage);
	
	lua_State *L;

	void PushIUnit(IUnit* unit);

	static IAI* ai;
	IGame* GetGame() const { return game; }
protected:

	swig_type_info* unittype;
	swig_type_info* damagePtr;
	bool LoadLuaFile(std::string filename);

	IGame* game;
};
