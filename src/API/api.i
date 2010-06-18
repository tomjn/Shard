#ifdef SWIG
%include <typemaps.i>
%include <carrays.i>
%include <std_string.i>
%include <std_vector.i>


%module api
%{
	#include <vector>
	#include "Position.h"
	#include "interfaces/IGame.h"
	#include "interfaces/IMapFeature.h"
	#include "interfaces/IAI.h"
	#include "interfaces/IUnitType.h"
	#include "interfaces/IUnit.h"
%}

%include "Position.h"
%include "interfaces/IGame.h"
%include "interfaces/IMapFeature.h"
%include "interfaces/IAI.h"
%include "interfaces/IUnitType.h"
%include "interfaces/IUnit.h"

%template(vectorUnitTypes) std::vector<IUnitType*>; 
%template(vectorUnits) std::vector<IUnit*>;

#endif
