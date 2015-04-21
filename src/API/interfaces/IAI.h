#pragma once

class IAI {
public:
	virtual ~IAI(){}
	virtual void Init()=0;
	virtual void Update()=0;
	virtual void GameEnd()=0;
	virtual void GameMessage(const char* text)=0;

	virtual void UnitCreated(IUnit* unit)=0;
	virtual void UnitBuilt(IUnit* unit)=0;
	virtual void UnitDead(IUnit* unit)=0;
	virtual void UnitIdle(IUnit* unit)=0;
	virtual void UnitMoveFailed(IUnit* unit)=0;

	virtual void UnitGiven(IUnit* unit)=0;

	virtual void UnitDamaged(IUnit* unit, IUnit* attacker, IDamage::Ptr damage)=0;
};
