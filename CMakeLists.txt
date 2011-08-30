### Generic native Skirmish AI config
#

set(mySourceDirRel         "src") # Common values are "" or "src"
set(additionalSources      ${CUtils_SRC})
set(additionalCompileFlags "")
set(additionalLibraries    ${Cpp_AIWRAPPER_TARGET} lua)


if    (BUILD_Cpp_AIWRAPPER)
	include_directories(BEFORE ${Cpp_AIWRAPPER_INCLUDE_DIRS})
	include_directories(BEFORE ${CMAKE_CURRENT_SOURCE_DIR}/src/lib)
	ConfigureNativeSkirmishAI(mySourceDirRel additionalSources additionalCompileFlags additionalLibraries)
else  (BUILD_Cpp_AIWRAPPER)
	message ("warning: Shard will not be built! (missing Cpp Wrapper)")
endif (BUILD_Cpp_AIWRAPPER)
