### Generic native Skirmish AI config
#

set(mySourceDirRel         "") # Common values are "" or "src"
set(additionalSources      ${CUtils_SRC})
set(additionalCompileFlags "")
set(additionalLibraries    ${Cpp_AIWRAPPER_TARGET})


if    (BUILD_Cpp_AIWRAPPER)
	include_directories(BEFORE ${CMAKE_CURRENT_SOURCE_DIR}/lib/lua)
	include_directories(BEFORE ${CMAKE_SOURCE_DIR})
	include_directories(BEFORE ${Cpp_AIWRAPPER_INCLUDE_DIRS})
	ConfigureNativeSkirmishAI(mySourceDirRel additionalSources additionalCompileFlags additionalLibraries)
else  (BUILD_Cpp_AIWRAPPER)
	message ("warning: Shard will not be built! (missing Cpp Wrapper)")
endif (BUILD_Cpp_AIWRAPPER)
