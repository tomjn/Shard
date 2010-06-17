#ifndef IMAPFEATURE_H
#define IMAPFEATURE_H

#include <string>
#include "../Position.h"

class IMapFeature {
public:

	virtual int ID()=0;
	virtual std::string Name()=0;
	virtual Position GetPosition()=0;
};


#endif
