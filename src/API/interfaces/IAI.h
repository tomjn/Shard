#pragma once

#include "IUnit.h"

class IAI {
public:
	virtual void Init()=0;
	virtual void Update()=0;
	virtual void GameEnd()=0;

	virtual void UnitCreated(IUnit* unit)=0;
	virtual void UnitBuilt(IUnit* unit)=0;
	virtual void UnitDead(IUnit* unit)=0;
	virtual void UnitIdle(IUnit* unit)=0;

	virtual void UnitDamaged(IUnit* unit, IUnit* attacker)=0;
};
