#ifndef IPLAYER_H
#define IPLAYER_H

#include <string>

class IPlayer {
public:
	virtual bool IsAI()=0;
	virtual std::string Name()=0;
};

#endif
