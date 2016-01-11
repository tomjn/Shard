#ifndef CSPRINGMAP_H
#define CSPRINGMAP_H

class CSpringMap : public IMap {
public:
	//
	CSpringMap(springai::OOAICallback* callback, CSpringGame* game);
	virtual ~CSpringMap();


	virtual std::string MapName() override;

	virtual int SpotCount() override;
	virtual Position GetSpot(int idx) override;
	virtual std::vector<Position>& GetMetalSpots() override;

	virtual Position MapDimensions() override;

	virtual std::vector<IMapFeature*> GetMapFeatures() override;
	virtual std::vector<IMapFeature*> GetMapFeaturesAt(Position p, double radius) override;

	virtual double MinimumWindSpeed() override;
	virtual double MaximumWindSpeed() override;
	virtual double AverageWind() override;

	virtual float MaximumHeight() override;
	virtual float MinimumHeight() override;

	virtual double TidalStrength() override;

	virtual Position FindClosestBuildSite(IUnitType* t, Position builderPos, double searchRadius, double minimumDistance) override;
	virtual Position FindClosestBuildSiteFacing(IUnitType* t, Position builderPos, double searchRadius, double minimumDistance,int facing) override;

	virtual bool CanBuildHere(IUnitType* t, Position pos) override;
	virtual bool CanBuildHereFacing(IUnitType* t, Position pos,int facing) override;

	springai::Resource* GetMetalResource();

protected:
	std::vector<IMapFeature*>::iterator GetMapFeatureIteratorById(int id);
	void UpdateMapFeatures();

	springai::OOAICallback* callback;
	CSpringGame* game;

	std::vector<Position> metalspots;
	springai::Resource* metal;
	springai::Map* map;
	std::vector< IMapFeature*> mapFeatures;
	int lastMapFeaturesUpdate;
};

#endif


