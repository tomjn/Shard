#ifndef SRESOURCE_H
#define SRESOURCE_H

#include <string>

struct SResourceData {
	SResourceData(){
		income = 0;
		usage = 0;
		name = "";
	}
	std::string name;
	double income;
	double usage;
	int capacity; // how much we can store (-1 for unlimited)
	int reserves; // how much is stored
	
	int gameframe; // the game frame these stats were recorded at
};

#endif
