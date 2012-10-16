#ifndef IMAPFEATURE_H
#define IMAPFEATURE_H

#include <string>


class IMapFeature {
public:
	virtual ~IMapFeature(){}
	virtual int ID()=0;
	virtual std::string Name()=0;
	virtual Position GetPosition()=0;

	virtual float ResourceValue(int idx)=0;
	virtual bool Reclaimable()=0;
};


#endif
