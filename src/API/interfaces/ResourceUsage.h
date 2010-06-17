#ifndef SRESOURCEUSAGE_H
#define SRESOURCEUSAGE_H

#include "Resource.h"

struct SResourceUsage {
	SResourceUsage(){
		consumption = 0;
		generation = 0;
	}
	SResource resource;
	double consumption;
	double generation;

	int gameframe; // the game frame these stats were recorded at
};

#endif
