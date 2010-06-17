#ifndef SPRINGMAPFEATURE_H
#define SPRINGMAPFEATURE_H

#include <string>
#include "../Position.h"

#include "../interfaces/IMapFeature.h"
#include "../interfaces/IGame.h"

class CSpringMapFeature : public IMapFeature {
public:
	
	CSpringMapFeature(springai::AICallback* callback, springai::Feature* f, IGame* game);
	virtual ~CSpringMapFeature();

	virtual int ID();
	virtual std::string Name();
	virtual Position GetPosition();

protected:
	springai::AICallback* callback;
	springai::Feature* feature;
	IGame* game;
};


#endif
