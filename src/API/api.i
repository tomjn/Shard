#ifdef SWIG
%include <typemaps.i>
%include <carrays.i>
%include <std_string.i>
%include <std_vector.i>
%include "boost_shared_ptr.i"

%module api
%{
	#include "interfaces/api.h"
%}

%include "Position.h"
%include "interfaces/ResourceData.h"
%include "interfaces/ResourceTransfer.h"
%include "interfaces/IDamage.h"
%include "interfaces/IMapFeature.h"
%include "interfaces/IMap.h"
%include "interfaces/IUnitType.h"
%include "interfaces/IUnit.h"
%include "interfaces/IGame.h"
%include "interfaces/IAI.h"

%template(damagePtr) boost::shared_ptr<IDamage>;
%template(unitPtr) boost::shared_ptr<IUnit>;
%template(vectorUnitTypes) std::vector<IUnitType*>; 
%template(vectorUnits) std::vector<IUnit*>;
%template(vectorFloat) std::vector<float>;
%template(vectorInt) std::vector<int>;
%template(vectorMapFeature) std::vector<IMapFeature*>;

#endif
