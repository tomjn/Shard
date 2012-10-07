#ifndef CSPRINGMAP_H
#define CSPRINGMAP_H

class CSpringMap : public IMap {
public:
	//
	CSpringMap(springai::OOAICallback* callback, CSpringGame* game);
	virtual ~CSpringMap();


	virtual std::string MapName();

	virtual int SpotCount();
	virtual Position GetSpot(int idx);
	virtual std::vector<Position>& GetMetalSpots();

	virtual Position MapDimensions();

	virtual std::vector<IMapFeature*> GetMapFeatures();
	virtual std::vector<IMapFeature*> GetMapFeaturesAt(Position p, double radius);

	virtual double MinimumWindSpeed();
	virtual double MaximumWindSpeed();
	virtual double AverageWind();

	virtual float MaxHeight();
	virtual float MinHeight();

	virtual double TidalStrength();

	virtual Position FindClosestBuildSite(IUnitType* t, Position builderPos, double searchRadius, double minimumDistance);
	virtual bool CanBuildHere(IUnitType* t, Position pos);
	
	springai::Resource* GetMetalResource();

protected:
	springai::OOAICallback* callback;
	CSpringGame* game;
	
	std::vector<Position> metalspots;
	springai::Resource* metal;
};

#endif
