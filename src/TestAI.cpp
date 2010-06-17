#include "TestAI.h"
//#include "API/swig.h"
#include "API/api_wrap.cxx"

IGame* global_game = 0;

int luaErrorHandler(lua_State *L) {
	lua_getfield(L, LUA_GLOBALSINDEX, "debug");
	if (!lua_istable(L, -1)) {
		lua_pop(L, 1);
		return 1;
	}
	lua_getfield(L, -1, "traceback");
	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 2);
		return 1;
	}
	lua_pushvalue(L, 1);
	lua_pushinteger(L, 0);
	lua_call(L, 2, 1);
	return 1;
}

int lua_epcall(lua_State *L, int nargs){
	//if( i != 0) {
	//	std::cout << "error running function `f': "<< lua_tostring(L, -1) << std::endl;
	//}
	//return i;

	//when i go to make a Lua call from c++ I do
	int size0 = lua_gettop(L);
	int error_index = lua_gettop(L) - nargs;

	//push error handler onto stack..
	lua_pushcfunction(L, luaErrorHandler);
	lua_insert(L, error_index);

	//call the function
	int status = lua_pcall(L, nargs, LUA_MULTRET, error_index);

	//report any errors
	if (status!=0)
	{
		//report just pops a string off the stack and print it to my console
//		report(L,status);
		int i = lua_gettop(L);
		while(i >= 0){
			
			if(::lua_isstring(L,i)){
				global_game->SendToConsole(lua_tostring(L, i));
//				std::cerr <<  << std::endl;
			}
			i--;
		}
		//std::cerr << std::endl;
	}
	

	//pop the error function
	lua_remove(L, error_index);
	int j = lua_gettop(L);
	lua_pop(L,j);

	return status;
}
IAI* CTestAI::ai = 0;
CTestAI::CTestAI(IGame* game)
: game(game){
	CTestAI::ai = this;
	global_game = game;

	// create our Lua environment
	L = lua_open();

	// load our libraries
	luaL_openlibs(L);
	luaopen_api(L);
	
	// Push in our IGame pointer
	SWIG_NewPointerObj(L,game,SWIGTYPE_p_IGame,0);
	lua_setglobal(L, "game_engine");

	// Setup LUA_PATH
	std::string f = game->ConfigFolderPath();
	f += "\\ai\\";
	std::string g = game->GameName()+"\\";
	std::string p;

	p  = f+g+"preload\\?;";
	p += f+g+"preload\\?.lua;";
	p += f+"preload\\?;";
	p += f+"preload\\?.lua;";
	
	p += f+g+"?;";
	p += f+g+"?.lua;";
	p += f+g+"preload\\?;";
	p += f+g+"preload\\?.lua;";
	
	p += f+"?;";
	p += f+"?.lua;";
	p += LUA_PATH_DEFAULT;

	lua_pushstring(L, "package");
	lua_gettable(L, LUA_GLOBALSINDEX);
	lua_pushstring(L, "path");
	lua_pushstring(L, p.c_str());
	lua_settable(L, -3);

	// now start the wheels turning
	LoadLuaFile("ai.lua");
}

void CTestAI::LoadLuaFile(std::string filename){
	std::string f = game->ConfigFolderPath();
	f += "\\ai\\";
	f += filename;
	int err = luaL_loadfile (L, f.c_str());
	if (err == 0){
		int status = lua_epcall (L, 0);
		if (status == 0){
			
	   }
	}
}

CTestAI::~CTestAI(){
	lua_close(L);
}


void CTestAI::Init(){
	lua_getglobal(L, "ai");
	lua_getfield(L, -1, "Init");
	lua_getglobal(L, "ai");
	if(lua_isfunction(L,-2)){
		lua_epcall(L, 1);
	}
}

void CTestAI::Update(){
	lua_getglobal(L, "ai");
	lua_getfield(L, -1, "Update");
	lua_getglobal(L, "ai");
	if(lua_isfunction(L,-2)){
		lua_epcall(L, 1);
	}
}

void CTestAI::GameEnd(){
	lua_getglobal(L, "ai");
	lua_getfield(L, -1, "GameEnd");
	lua_getglobal(L, "ai");
	if(lua_isfunction(L,-2)){
		lua_epcall(L, 1);
	}
}


void CTestAI::UnitCreated(IUnit* unit){
	lua_getglobal(L, "ai");
	lua_getfield(L, -1, "UnitCreated");
	lua_getglobal(L, "ai");
	SWIG_NewPointerObj(L,unit,SWIGTYPE_p_IUnit,0);
	if(lua_isfunction(L,-3)){
		lua_epcall(L, 2);
	}
}

void CTestAI::UnitBuilt(IUnit* unit){
	lua_getglobal(L, "ai");
	lua_getfield(L, -1, "UnitBuilt");
	lua_getglobal(L, "ai");
	SWIG_NewPointerObj(L,unit,SWIGTYPE_p_IUnit,0);
	if(lua_isfunction(L,-3)){
		lua_epcall(L, 2);
	}
}

void CTestAI::UnitDead(IUnit* unit){
	lua_getglobal(L, "ai");
	lua_getfield(L, -1, "UnitDead");
	lua_getglobal(L, "ai");
	SWIG_NewPointerObj(L,unit,SWIGTYPE_p_IUnit,0);
	if(lua_isfunction(L,-3)){
		lua_epcall(L, 2);
	}
}

void CTestAI::UnitIdle(IUnit* unit){
	lua_getglobal(L, "ai");
	lua_getfield(L, -1, "UnitIdle");
	lua_getglobal(L, "ai");
	SWIG_NewPointerObj(L,unit,SWIGTYPE_p_IUnit,0);
	if(lua_isfunction(L,-3)){
		lua_epcall(L, 2);
	}
}

void CTestAI::UnitDamaged(IUnit* unit, IUnit* attacker){
	lua_getglobal(L, "ai");
	lua_getfield(L, -1, "UnitDamaged");
	lua_getglobal(L, "ai");
	SWIG_NewPointerObj(L,unit,SWIGTYPE_p_IUnit,0);
	SWIG_NewPointerObj(L,attacker,SWIGTYPE_p_IUnit,0);
	if(lua_isfunction(L,-4)){
		lua_epcall(L, 3);
	}
}

void CTestAI::PushIUnit(IUnit* unit){
	SWIG_NewPointerObj(L,unit,SWIGTYPE_p_IUnit,1);
}
