#include "TestAI.h"

#ifdef _WIN32
	#define SLASH "\\"
#else
	#define SLASH "/"
#endif

IGame* global_game = 0;

extern "C" {
	extern int  luaopen_api(lua_State* L);
}
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
	this->L = luaL_newstate();

	// load our libraries
	luaL_openlibs(this->L);
	// load SWIG generated apis
	luaopen_api(this->L);
	
	unittype = SWIG_TypeQuery(this->L,"IUnit *");
	damagePtr = SWIG_TypeQuery(this->L, "IDamage::Ptr *");

	// Push in our IGame pointer
	swig_type_info* type = SWIG_TypeQuery(this->L,"IGame *");
	SWIG_NewPointerObj(this->L,game,type,0);
	lua_setglobal(this->L, "game_engine");

	// Setup LUA_PATH
	std::string f = "ai";
	f += SLASH;
	game->LocatePath(f);

	std::string g = game->GameName()+SLASH;
	std::string p;

	p  = f+g+"preload"+SLASH+"?;";
	p += f+g+"preload"+SLASH+"?.lua;";
	p += f+"preload"+SLASH+"?;";
	p += f+"preload"+SLASH+"?.lua;";
	
	p += f+g+"?;";
	p += f+g+"?.lua;";
	p += f+g+"preload"+SLASH+"?;";
	p += f+g+"preload"+SLASH+"?.lua;";
	
	p += f+"?;";
	p += f+"?.lua;";
	p += LUA_PATH_DEFAULT;

	lua_pushstring(this->L, "package");
	lua_gettable(this->L, LUA_GLOBALSINDEX);
	lua_pushstring(this->L, "path");
	lua_pushstring(this->L, p.c_str());
	lua_settable(this->L, -3);

	// now start the wheels turning
	LoadLuaFile("ai.lua");
}


bool CTestAI::LoadLuaFile(std::string filename){
	filename.insert(0,"ai" SLASH); //prepend "ai/"
	if (!game->LocatePath(filename)){
		return false;
	}
	int err = luaL_loadfile (this->L, filename.c_str());
	if (err == 0){
		int status = lua_epcall (this->L, 0);
		if (status == 0){
			return true;
		} else{
			return false;
		}
	} else {
		std::string message = "error loading \"";
		message += filename;
		message += "\" with error code: ";
		message += err;
		this->game->SendToConsole(message);
		return false;
	}
}

CTestAI::~CTestAI(){
	lua_close(this->L);
}


void CTestAI::Init(){
	lua_getglobal(this->L, "ai");
	lua_getfield(this->L, -1, "Init");
	lua_getglobal(this->L, "ai");
	if(lua_isfunction(this->L,-2)){
		lua_epcall(this->L, 1);
	}
}

void CTestAI::Update(){
	lua_getglobal(this->L, "ai");
	lua_getfield(this->L, -1, "Update");
	lua_getglobal(this->L, "ai");
	if(lua_isfunction(this->L,-2)){
		lua_epcall(this->L, 1);
	}
}

void CTestAI::GameEnd(){
	lua_getglobal(this->L, "ai");
	lua_getfield(this->L, -1, "GameEnd");
	lua_getglobal(this->L, "ai");
	if(lua_isfunction(this->L,-2)){
		lua_epcall(this->L, 1);
	}
}

void CTestAI::GameMessage(const char* text){
	lua_getglobal(this->L, "ai");
	lua_getfield(this->L, -1, "GameMessage");
	lua_getglobal(this->L, "ai");
	lua_pushstring(this->L,text);
	//SWIG_NewPointerObj(this->L,text,(char *),0);
	if(lua_isfunction(this->L,-3)){
		lua_epcall(this->L, 2);
	}
}

void CTestAI::UnitGiven(IUnit* unit){
	lua_getglobal(this->L, "ai");
	lua_getfield(this->L, -1, "UnitGiven");
	lua_getglobal(this->L, "ai");
	SWIG_NewPointerObj(this->L,unit,unittype,0);
	if(lua_isfunction(this->L,-3)){
		lua_epcall(this->L, 2);
	}
}

void CTestAI::UnitCreated(IUnit* unit){
	lua_getglobal(this->L, "ai");
	lua_getfield(this->L, -1, "UnitCreated");
	lua_getglobal(this->L, "ai");
	SWIG_NewPointerObj(this->L,unit,unittype,0);
	if(lua_isfunction(this->L,-3)){
		lua_epcall(this->L, 2);
	}
}

void CTestAI::UnitBuilt(IUnit* unit){
	lua_getglobal(this->L, "ai");
	lua_getfield(this->L, -1, "UnitBuilt");
	lua_getglobal(this->L, "ai");
	SWIG_NewPointerObj(this->L,unit,unittype,0);
	if(lua_isfunction(this->L,-3)){
		lua_epcall(this->L, 2);
	}
}

void CTestAI::UnitDead(IUnit* unit){
	lua_getglobal(this->L, "ai");
	lua_getfield(this->L, -1, "UnitDead");
	lua_getglobal(this->L, "ai");
	SWIG_NewPointerObj(this->L,unit,unittype,0);
	if(lua_isfunction(this->L,-3)){
		lua_epcall(this->L, 2);
	}
}

void CTestAI::UnitIdle(IUnit* unit){
	lua_getglobal(this->L, "ai");
	lua_getfield(this->L, -1, "UnitIdle");
	lua_getglobal(this->L, "ai");
	SWIG_NewPointerObj(this->L,unit,unittype,0);
	if(lua_isfunction(this->L,-3)){
		lua_epcall(this->L, 2);
	}
}

void CTestAI::UnitMoveFailed(IUnit* unit){
	lua_getglobal(this->L, "ai");
	lua_getfield(this->L, -1, "UnitMoveFailed");
	lua_getglobal(this->L, "ai");
	SWIG_NewPointerObj(this->L,unit,unittype,0);
	if(lua_isfunction(this->L,-3)){
		lua_epcall(this->L, 2);
	}
}

void CTestAI::UnitDamaged(IUnit* unit, IUnit* attacker, IDamage::Ptr damage){
	lua_getglobal(this->L, "ai");
	lua_getfield(this->L, -1, "UnitDamaged");
	lua_getglobal(this->L, "ai");
	SWIG_NewPointerObj(this->L,unit,unittype,0);
	SWIG_NewPointerObj(this->L,attacker,unittype,0);
	IDamage::Ptr* ptrptr = new IDamage::Ptr(damage);
	SWIG_NewPointerObj(this->L,ptrptr,damagePtr,1);
	if(lua_isfunction(this->L,-4)){
		lua_epcall(this->L, 3);
	}
}

void CTestAI::PushIUnit(IUnit* unit){
	SWIG_NewPointerObj(this->L,unit,unittype,1);
}
