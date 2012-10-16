#ifndef ITEAM_H
#define ITEAM_H

#include "IPlayer.h"

class ITeam {
public:
	virtual ~ITeam(){}
	virtual int ID()=0;
	virtual int Size()=0;
	virtual IPlayer* Player(int idx)=0;
};
#endif
