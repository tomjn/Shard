#ifndef SRESOURCE_H
#define SRESOURCE_H

#include <string>

class SResourceData {
public:
	SResourceData(){
		this->income = 0;
		this->usage = 0;
		this->name = "";
		this->id = 0;
		this->reserves = 0;
		this->capacity = 0;
		this->gameframe = 0;
	}
	int id;
	std::string name;
	double income;
	double usage;
	int capacity; // how much we can store (-1 for unlimited)
	int reserves; // how much is stored
	
	int gameframe; // the game frame these stats were recorded at
};

#endif
