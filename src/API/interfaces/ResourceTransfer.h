#ifndef SRESOURCEUSAGE_H
#define SRESOURCEUSAGE_H


struct SResourceTransfer {
	SResourceTransfer(){
		consumption = 0;
		generation = 0;
		rate = 1;
	}
	SResourceData resource;

	unsigned int rate;

	double consumption;
	double generation;

	int gameframe; // the game frame these stats were recorded at
};

#endif
