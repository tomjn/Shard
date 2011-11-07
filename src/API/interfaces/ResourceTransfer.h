#ifndef SRESOURCEUSAGE_H
#define SRESOURCEUSAGE_H


class SResourceTransfer {
public:
	SResourceTransfer(){
		this->consumption = 0;
		this->generation = 0;
		this->rate = 1;
		this->gameframe = 0;
	}
	SResourceData resource;

	unsigned int rate;

	double consumption;
	double generation;

	int gameframe; // the game frame these stats were recorded at
};

#endif
