#ifndef POSITION_H
#define POSITION_H

class Position {
public:
	Position(float xpos, float ypos, float zpos): x(xpos), y(ypos), z(zpos) {}
	Position() : x(0.0f), y(0.0f), z(0.0f) {}

	float x;
	float y;
	float z;
};

#endif
