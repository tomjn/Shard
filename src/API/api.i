#ifdef SWIG
%include <typemaps.i>
%include <carrays.i>
%include <std_string.i>
%include <std_vector.i>


%module api
%{
	#include "interfaces/api.h"
%}

%include "Position.h"
%include "interfaces/ResourceData.h"
%include "interfaces/ResourceTransfer.h"
%include "interfaces/IMapFeature.h"
%include "interfaces/IMap.h"
%include "interfaces/IUnitType.h"
%include "interfaces/IUnit.h"
%include "interfaces/IGame.h"
%include "interfaces/IAI.h"


%template(vectorUnitTypes) std::vector<IUnitType*>; 
%template(vectorUnits) std::vector<IUnit*>;
%template(vectorFloat) std::vector<float>;
%template(vectorInt) std::vector<int>;
%template(vectorMapFeature) std::vector<IMapFeature*>;

#endif
