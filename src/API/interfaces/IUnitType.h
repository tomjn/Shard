#pragma once

class IUnitType {
public:

	virtual std::string Name()=0;

	virtual bool CanDeploy()=0;
	virtual bool CanMoveWhenDeployed()=0;
	virtual bool CanFireWhenDeployed()=0;
	virtual bool CanBuildWhenDeployed()=0;
	virtual bool CanBuildWhenNotDeployed()=0;

	virtual bool Extractor()=0;

	virtual float GetMaxHealth()=0;

	virtual int WeaponCount()=0;

	virtual std::vector<IUnitType*> BuildOptions()=0;

};
