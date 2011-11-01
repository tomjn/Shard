#ifndef SPRINGMAPFEATURE_H
#define SPRINGMAPFEATURE_H

#include <string>
#include "../Position.h"

#include "../interfaces/IMapFeature.h"
#include "../interfaces/IGame.h"

class CSpringMapFeature : public IMapFeature {
public:
	
	CSpringMapFeature(springai::OOAICallback* callback, springai::Feature* f, IGame* game);
	virtual ~CSpringMapFeature();

	virtual int ID();
	virtual std::string Name();
	virtual Position GetPosition();

	virtual float ResourceValue(int idx);
	virtual bool Reclaimable();

	springai::Feature* feature;
protected:
	springai::OOAICallback* callback;
	IGame* game;
};


#endif
