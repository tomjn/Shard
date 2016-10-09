### Generic native Skirmish AI config
#

set(mySourceDirRel         "") # Common values are "" or "src"
set(additionalSources      "")
set(additionalCompileFlags "")
set(additionalLibraries    ${Cpp_AIWRAPPER_TARGET} CUtils)


get_directory_property(hasParent PARENT_DIRECTORY)
if (hasParent)
	if    (BUILD_Cpp_AIWRAPPER)
		include_directories(BEFORE ${CMAKE_BINARY_DIR}) # for src-generated wrapper files
		include_directories(BEFORE ${CMAKE_SOURCE_DIR})
		include_directories(BEFORE ${Cpp_AIWRAPPER_INCLUDE_DIRS})
		include_directories(BEFORE ${CMAKE_CURRENT_SOURCE_DIR}/lib/lua)
		if(NOT WIN32)
			add_definitions(-DLUA_USE_POSIX)
		endif()
		ConfigureNativeSkirmishAI(mySourceDirRel additionalSources additionalCompileFlags additionalLibraries)
	else  (BUILD_Cpp_AIWRAPPER)
		message ("warning: Shard will not be built! (missing Cpp Wrapper)")
	endif (BUILD_Cpp_AIWRAPPER)
else()
	cmake_minimum_required(VERSION 2.8)

	message(WARNING "Outside of spring source build: the resulting shared lib won't work! (Symbols not found...)")

	add_library(SkirmishAI SHARED
		src/TestAI.cpp
		src/AIExport.cpp
		src/CppTestAI.cpp
		src/API/spring/SpringMap.cpp
		src/API/spring/SpringDamage.cpp
		src/API/spring/SpringMapFeature.cpp
		src/API/spring/SpringUnitType.cpp
		src/API/spring/SpringGame.cpp
		src/API/spring/SpringUnit.cpp
		src/API/api_wrap.cpp
	)
	target_include_directories(SkirmishAI PRIVATE
		lib/lua
		spring-ai-includes/rts
		spring-ai-includes
		spring-ai-includes/AI/Wrappers/Cpp/src
	)
	target_compile_definitions(SkirmishAI PRIVATE -DBUILDING_SKIRMISH_AI -DBUILDING_AI)
	target_compile_features(SkirmishAI PRIVATE cxx_range_for)
endif()
