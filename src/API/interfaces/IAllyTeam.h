#ifndef IALLYTEAM_H
#define IALLYTEAM_H

class IAllyTeam {
public:
	virtual ~IAllyTeam(){}
	virtual int ID()=0;
	virtual int Size()=0;
	virtual ITeam* Team(int idx)=0;
	virtual bool Friendly()=0;
};

#endif
