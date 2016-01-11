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

	virtual int ID() override;
	virtual std::string Name() override;
	virtual Position GetPosition() override;

	virtual float ResourceValue(int idx) override;
	virtual bool Reclaimable() override;

	springai::Feature* feature;
protected:
	springai::OOAICallback* callback;
	IGame* game;
	springai::FeatureDef* def;
};


#endif
