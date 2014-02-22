.PHONY: api_wrap.cpp swig.h

all: api_wrap.cpp swig.h

api_wrap.cpp:
	swig -c++ -lua -o api_wrap.cpp api.i

swig.h:
	swig -lua -external-runtime swig.h
