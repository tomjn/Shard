function widget:GetInfo()
	return {
		name	= "Shard Help: Draw",
		desc	= "draw stuff in-game that Shard tells me to",
		author	= "eronoobos",
		date 	= "June 2016",
		license	= "whatever",
		layer 	= 0,
		enabled	= true
	}
end

local lineArrowSize = 80

local aiTeams = {}
local emptyShapeIDs = {}
local teamChannelByID = {}
local commandBindings = {}
local shapeIDCounter = 0
local lastCamState
local selectedTeamID
local selectedChannel
local lastTeamID
local lastChannel
local needUpdateRectangles, needUpdateCircles, needUpdateLines, needUpdatePoints, needUpdateLabels
local displayOnOff = true
local shapeCount = 0
local lastKey
local shapesByString = {}

local colorLocations = {
	Rectangle = 5,
	Circle = 4,
	Line = 5,
	Point = 3,
}

local coordNames = { x, z, x1, z1, x2, z2, radius, y }

local rectangleDisplayList = 0
local circleDisplayList = 0
local lineDisplayList = 0
local pointDisplayList = 0
local labelDisplayList = 0

local tRemove = table.remove
local mCeil = math.ceil
local mAbs = math.abs
local mSqrt = math.sqrt
local mCos = math.cos
local mSin = math.sin
local twicePi = math.pi * 2
local mMin = math.min
local mMax = math.max

local spIsSphereInView = Spring.IsSphereInView
local spGetGroundHeight = Spring.GetGroundHeight
local spGetGroundInfo = Spring.GetGroundInfo
local spWorldToScreenCoords = Spring.WorldToScreenCoords
local spGetCameraState = Spring.GetCameraState
local spEcho = Spring.Echo
local spGetViewGeometry = Spring.GetViewGeometry
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam

local glCreateList = gl.CreateList
local glCallList = gl.CallList
local glDeleteList = gl.DeleteList
local glColor = gl.Color
local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glDepthTest = gl.DepthTest
local glLineWidth = gl.LineWidth
local glPointSize = gl.PointSize
local glTranslate = gl.Translate
local glBillboard = gl.Billboard
-- local glText = gl.Text
-- local glBeginText = gl.BeginText
-- local glEndText = gl.EndText
local glLoadFont = gl.LoadFont
local glBlending = gl.Blending
local glUnitShape = gl.UnitShape

local GL_TRIANGLE_STRIP = GL.TRIANGLE_STRIP
local GL_TRIANGLE_FAN = GL.TRIANGLE_FAN
local GL_LINE_STRIP = GL.LINE_STRIP
local GL_LINE_LOOP = GL.LINE_LOOP
local GL_POINTS = GL.POINTS

local function justWords(str)
  local words = {}
  for word in str:gmatch("%w+") do table.insert(words, word) end
  return words
end

local function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
   end
   return Table
end

local function trim(s)
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

local function normalizeVector2d(vx, vy)
	if vx == 0 and vy == 0 then return 0, 0 end
	local dist = mSqrt(vx*vx + vy*vy)
	return vx/dist, vy/dist, dist
end

-- using GL_POINT
local function doPoint(x, y, z)
	glVertex(x, y, z)
end

-- using GL_LINE_STRIP
local function doLine(x1, y1, z1, x2, y2, z2)
    gl.Vertex(x1, y1, z1)
    gl.Vertex(x2, y2, z2)
end

-- using GL_TRIANGLE_STRIP
local function doTriangle(x1, y1, z1, x2, y2, z2, x3, y3, z3)
	glVertex(x1, y1, z1)
    glVertex(x2, y2, z2)
    glVertex(x3, y3, z3)
end

-- using GL_TRIANGLE_FAN
local function doCircle(x, y, z, radius, sides)
	local sideAngle = twicePi / sides
	glVertex(x, y, z)
	for i = 1, sides+1 do
		local cx = x + (radius * mCos(i * sideAngle))
		local cz = z + (radius * mSin(i * sideAngle))
		glVertex(cx, y, cz)
	end
end

-- using GL_LINE_LOOP
local function doEmptyCircle(x, y, z, radius, sides)
	local sideAngle = twicePi / sides
	for i = 1, sides do
		local cx = x + (radius * mCos(i * sideAngle))
		local cz = z + (radius * mSin(i * sideAngle))
		glVertex(cx, y, cz)
	end
end

-- using GL_LINE_LOOP
local function doEmptyCircle2d(x, y, radius, sides)
	local sideAngle = twicePi / sides
	for i = 1, sides do
		local cx = x + (radius * mCos(i * sideAngle))
		local cy = y + (radius * mSin(i * sideAngle))
		glVertex(cx, cy)
	end
end

-- using GL_TRIANGLE_STRIP
local function doRectangleFlat(x1, z1, x2, z2, y)
	glVertex(x1, y, z1)
	glVertex(x2, y, z1)
	glVertex(x2, y, z2)
	glVertex(x1, y, z1)
	glVertex(x1, y, z2)
	glVertex(x2, y, z2)
end

-- using GL_TRIANGLE_STRIP
-- local function doRectangleContoured(x1, z1, x2, z2, y1, y2, y3, y4)
-- 	glVertex(x1, y1, z1)
-- 	glVertex(x2, y2, z1)
-- 	glVertex(x2, y3, z2)
-- 	glVertex(x1, y1, z1)
-- 	glVertex(x1, y4, z2)
-- 	glVertex(x2, y3, z2)
-- end

-- using GL_LINE_LOOP
local function doEmptyRectangle(x1, z1, x2, z2, y)
	glVertex(x1, y, z1)
	glVertex(x2, y, z1)
	glVertex(x2, y, z2)
	glVertex(x1, y, z2)
end

local function CameraStatesMatch(stateA, stateB)
	if not stateA or not stateB then return end
	if #stateA ~= #stateB then return end
	for key, value in pairs(stateA) do
		if value ~= stateB[key] then return end
	end
	for key, value in pairs(stateB) do
		if value ~= stateA[key] then return end
	end
	return true
end

local function colorByTable(color)
	glColor(color[1], color[2], color[3], color[4])
end

local function GetShapes(teamID, channel)
	channel = channel or 1
	if not aiTeams[teamID] then
		aiTeams[teamID] = {}
	end
	if not aiTeams[teamID][channel] then
		aiTeams[teamID][channel] = {}
	end
	return aiTeams[teamID][channel]
end

local function DrawRectangles(shapes)
	glDepthTest(false)
	glPushMatrix()
	glLineWidth(2)
	for i = 1, #shapes do
		local shape = shapes[i]
		if shape.type == "rectangle" then
			colorByTable(shape.color)
			if shape.filled then
				if type(shape.filled) == 'string' then
					glBlending(shape.filled)
				end
				glBeginEnd(GL_TRIANGLE_STRIP, doRectangleFlat, shape.x1, shape.z1, shape.x2, shape.z2, shape.y)
				if type(shape.filled) == 'string' then
					glBlending('reset')
				end
			else
				glBeginEnd(GL_LINE_LOOP, doEmptyRectangle, shape.x1, shape.z1, shape.x2, shape.z2, shape.y)
			end
		end
	end
	glLineWidth(1)
	glColor(1, 1, 1, 0.5)
	glPopMatrix()
end

local function DrawCircles(shapes)
	glDepthTest(false)
	glPushMatrix()
	glLineWidth(2)
	for i = 1, #shapes do
		local shape = shapes[i]
		if shape.type == "circle" then
			colorByTable(shape.color)
			if shape.filled then
				if type(shape.filled) == 'string' then
					glBlending(shape.filled)
				end
				glBeginEnd(GL_TRIANGLE_FAN, doCircle, shape.x, shape.y, shape.z, shape.radius, shape.sides)
				if type(shape.filled) == 'string' then
					glBlending('reset')
				end
			else
				glBeginEnd(GL_LINE_LOOP, doEmptyCircle, shape.x, shape.y, shape.z, shape.radius, shape.sides)
			end
		end
	end
	glLineWidth(1)
	glColor(1, 1, 1, 0.5)
	glDepthTest(true)
	glPopMatrix()
end

local function DrawLines(shapes)
	glDepthTest(false)
	glPushMatrix()
	glLineWidth(2)
	for i = 1, #shapes do
		local shape = shapes[i]
		if shape.type == "line" then
			colorByTable(shape.color)
			glBeginEnd(GL_LINE_STRIP, doLine, shape.x1, shape.y1, shape.z1, shape.x2, shape.y2, shape.z2)
			if shape.arrow then
				glBeginEnd(GL_TRIANGLE_STRIP, doTriangle, shape.x2, shape.y2, shape.z2, shape.ax1, shape.y2, shape.az1, shape.ax2, shape.y2, shape.az2)
			end
		end
	end
	glLineWidth(1)
	glColor(1, 1, 1, 0.5)
	glDepthTest(true)
	glPopMatrix()
end

local function DrawPoints(shapes)
	glDepthTest(false)
	glPushMatrix()
	glPointSize(6)
	for i = 1, #shapes do
		local shape = shapes[i]
		if shape.type == "point" then
			colorByTable(shape.color)
			glBeginEnd(GL_POINTS, doPoint, shape.x, shape.y, shape.z)
		end
	end
	glPointSize(1)
	glColor(1, 1, 1, 0.5)
	glDepthTest(true)
	glPopMatrix()
end

local function DrawUnits(shapes)
	glDepthTest(false)
	glLineWidth(3)
	glPushMatrix()
	for i = 1, #shapes do
		local shape = shapes[i]
		if shape.type == "unit" then
			colorByTable(shape.color)
			glTranslate(shape.x, shape.y, shape.z)
			glBillboard()
			glBeginEnd(GL_LINE_LOOP, doEmptyCircle2d, 0, 0, shape.radius, shape.sides)
		end
	end
	glColor(1, 1, 1, 0.5)
	glPopMatrix()
	glLineWidth(1)
	glDepthTest(true)
end

local function DrawLabels(shapes)
	-- glBeginText()
	myFont:Begin()
	local labels = {}
	for i = 1, #shapes do
		local shape = shapes[i]
		if shape.label and spIsSphereInView(shape.x, shape.y, shape.z, 50) then
			-- colorByTable(shape.color)
			local sx, sy = spWorldToScreenCoords(shape.x, shape.y, shape.z)
			local halfWidth = shape.halfLabelWidth
			for l = 1, #labels do
				local label = labels[l]
				if mAbs(label.sx - sx) < halfWidth + label.halfWidth then
					local dy = mAbs(label.sy - sy)
					if dy < 16 then
						sy = sy + (16-dy)
					end
				end
			end
			-- glText(shape.label, sx, sy, 12, "cd")
			local c = shape.color
			myFont:SetTextColor(c[1], c[2], c[3], 1)
			myFont:SetOutlineColor(shape.textOutlineColor)
			myFont:Print(shape.label, sx, sy, 12, "cdo")
			labels[#labels+1] = {sx=sx, sy=sy, halfWidth=halfWidth}
		end
	end
	myFont:End()
	-- glEndText()
end

local function DrawInterface()
	local viewX, viewY, posX, posY = spGetViewGeometry()
	local centerX = mCeil(viewX/2)
	local centerY = mCeil(viewY/2)
	local quarterX = mCeil(viewX * 0.25)
	local threeQuartersY = mCeil(viewY * 0.75)
	myMonoFont:Begin()
	myMonoFont:SetTextColor(1, 1, 1, 1)
	local teamParenthesis = 'press t to change'
	local channelParenthesis = 'press c to change'
	if lastKey == 99 then -- c
		channelParenthesis = 'press 1 through 9 to change'
		local y = threeQuartersY
		for channel, shapes in pairs(aiTeams[selectedTeamID]) do
			myMonoFont:Print('Channel ' .. channel .. " has " .. #shapes .. " shapes", quarterX, y, 16, "do")
			y = y - 24
		end
	elseif lastKey == 116 then -- t
		teamParenthesis = 'press 0 through 9 to change'
		local y = threeQuartersY
		for teamID, channels in pairs(aiTeams) do
			local chnCnt = 0
			local shpCnt = 0
			for channel, shapes in pairs(channels) do
				chnCnt = chnCnt + 1
				shpCnt = shpCnt + #shapes
			end
			myMonoFont:Print('Team ' .. teamID .. " has " .. chnCnt .. " channels and " .. shpCnt .. " shapes", quarterX, y, 16, "do")
			y = y - 24
		end
	end
	local shapes = GetShapes(selectedTeamID, selectedChannel)
	myMonoFont:Print('Team    ' .. selectedTeamID .. ' (' .. teamParenthesis .. ')', quarterX, 32, 16, "do")
	myMonoFont:Print('Channel ' .. selectedChannel .. ' (' .. channelParenthesis .. ')', quarterX, 56, 16, "do")
	myMonoFont:Print(#shapes .. ' Shapes in current Channel of current Team, of ' .. shapeCount .. ' total shapes', quarterX, 80, 16, "do")
	myMonoFont:End()
end

local function UpdateInterface()
	needUpdateInterface = true
end

local function UpdateLabels()
	needUpdateLabels = true
	UpdateInterface()
end

local function UpdateShapesByType(shapeType)
	if not shapeType then
		needUpdateRectangles = true
		needUpdateCircles = true
		needUpdateLines = true
		needUpdatePoints = true
	elseif shapeType == "rectangle" then
		needUpdateRectangles = true
	elseif shapeType == "circle" then
		needUpdateCircles = true
	elseif shapeType == "line" then
		needUpdateLines = true
	elseif shapeType == "point" then
		needUpdatePoints = true
	end
	UpdateLabels()
end

local function GetShapeID()
	if #emptyShapeIDs > 0 then
		return tRemove(emptyShapeIDs)
	end
	shapeIDCounter = shapeIDCounter + 1
	return shapeIDCounter
end

local function GetShapeString(shape)
	local shapeString = shape.x .. " " .. shape.z .. " " .. tostring(shape.filled)
	if shape.x1 then
		shapeString = shapeString .. " " .. shape.x1 .. " " .. shape.z1 .. " " .. shape.x2 .. " " .. shape.z2
	end
	return shapeString
end

local function AddShape(shape, teamID, channel)
	channel = channel or 1
	shape.id = GetShapeID()
	local color = shape.color or {1, 1, 1, 0.5}
	color[1] = color[1] or 1
	color[2] = color[2] or 1
	color[3] = color[3] or 1
	color[4] = color[4] or 0.5
	shape.color = color
	local perceivedBrightness = mSqrt( 0.241*(color[1]^2) + 0.691*(color[2]^2) + 0.068*(color[3]^2) )
	if perceivedBrightness < 0.5 then
		shape.textOutlineColor = {1,1,1,1}
	else
		shape.textOutlineColor = {0,0,0,1}
	end
	if shape.label then
		shape.halfLabelWidth = myFont:GetTextWidth(shape.label) * 6
	end
	local shapes = GetShapes(teamID, channel)
	local shapeString = GetShapeString(shape)
	shapesByString[shapeString] = shapesByString[shapeString] or {}
	shape.y = shape.y + #shapesByString[shapeString] -- so that overlapping semitransparent shapes have an order
	shape.string = shapeString
	shapesByString[shapeString][#shapesByString[shapeString]+1] = shape
	lastTeamID = teamID
	lastChannel = channel
	shapes[#shapes+1] = shape
	teamChannelByID[shape.id] = {teamID = teamID, channel = channel}
	UpdateShapesByType(shape.type)
	shapeCount = shapeCount + 1
	return shape.id
end

local function AddRectangle(x1, z1, x2, z2, color, label, filled, teamID, channel)
	x1, z1, x2, z2 = mCeil(x1), mCeil(z1), mCeil(x2), mCeil(z2)
	local xAvg = mCeil( (x1 + x2) / 2 )
	local zAvg = mCeil( (z1 + z2) / 2 )
	local shape = {
		type = "rectangle",
		x = xAvg,
		z = zAvg,
		y = spGetGroundHeight(xAvg, zAvg),
		x1 = x1,
		z1 = z1,
		x2 = x2,
		z2 = z2,
		-- y1 = spGetGroundHeight(x1, z1),
		-- y2 = spGetGroundHeight(x2, z1),
		-- y3 = spGetGroundHeight(x2, z2),
		-- y4 = spGetGroundHeight(x1, z2),
		color = color,
		label = label,
		filled = filled,
	}
	return AddShape(shape, teamID, channel)
end

local function AddCircle(x, z, radius, color, label, filled, teamID, channel)
	x, z, radius = mCeil(x), mCeil(z), mCeil(radius)
	local shape = {
		type = "circle",
		x = x,
		z = z,
		y = spGetGroundHeight(x, z),
		radius = radius,
		color = color,
		label = label,
		filled = filled,
		sides = mCeil(mSqrt(radius*2)),
	}
	return AddShape(shape, teamID, channel)
end

local function AddLine(x1, z1, x2, z2, color, label, arrow, teamID, channel)
	x1, z1, x2, z2 = mCeil(x1), mCeil(z1), mCeil(x2), mCeil(z2)
	local xAvg = mCeil( (x1 + x2) / 2 )
	local zAvg = mCeil( (z1 + z2) / 2 )
	local shape = {
		type = "line",
		x = xAvg,
		z = zAvg,
		y = spGetGroundHeight(xAvg, zAvg),
		x1 = x1,
		z1 = z1,
		y1 = spGetGroundHeight(x1, z1),
		x2 = x2,
		z2 = z2,
		y2 = spGetGroundHeight(x2, z2),
		color = color,
		label = label,
		arrow = arrow,
	}
	if arrow then
		local dx = x2 - x1
		local dz = z2 - z1
		local vx, vz, dist = normalizeVector2d(dx, dz)
		local arrowSize = mMin(lineArrowSize, dist)
		local arrowSizeHalf = arrowSize / 2
		local backX, backZ = x2-(vx*arrowSize), z2-(vz*arrowSize)
		local ax1, az1 = backX+(vz*arrowSizeHalf), backZ-(vx*arrowSizeHalf)
		local ax2, az2 = backX-(vz*arrowSizeHalf), backZ+(vx*arrowSizeHalf)
		shape.ax1, shape.az1, shape.ax2, shape.az2 = ax1, az1, ax2, az2
	end
	return AddShape(shape, teamID, channel)
end

local function AddPoint(x, z, color, label, teamID, channel)
	x, z = mCeil(x), mCeil(z)
	local y = spGetGroundHeight(x, z)
	local shape = {
		type = "point",
		x = x,
		z = z,
		y = y,
		color = color,
		label = label,
	}
	return AddShape(shape, teamID, channel)
end

local function AddUnit(unitID, color, label, teamID, channel)
	local x, y, z = spGetUnitPosition(unitID)
	local unitDefID = spGetUnitDefID(unitID)
	local radius = mMax(UnitDefs[unitDefID].xsize, UnitDefs[unitDefID].zsize) * 5
	color = color or {}
	color[4] = 1
	local shape = {
		type = "unit",
		unitID = unitID,
		unitDefID = unitDefID,
		teamID = spGetUnitTeam(unitID),
		x = x,
		y = y,
		z = z,
		radius = radius,
		sides = mCeil(mSqrt(radius*2)),
		color = color,
		label = label,
	}
	return AddShape(shape, teamID, channel)
end

local function EraseShape(id, address)
	local found = false
	local tc = teamChannelByID[id]
	if not tc then
		return false
	end
	local shapes = GetShapes(tc.teamID, tc.channel)
	if not address then
		for i = #shapes, 1, -1 do
			local shape = shapes[i]
			if shape.id == id then
				address = i
				break
			end
		end
	end
	if address and shapes[address] then
		emptyShapeIDs[#emptyShapeIDs+1] = id
		teamChannelByID[id] = nil
		local foundShape = tRemove(shapes, address)
		shapesByString[foundShape.string] = nil
		UpdateShapesByType(foundShape.type)
		found = true
		shapeCount = shapeCount - 1
	end
	return found
end

local function EraseShapes(attributes, teamID, channel)
	for k, v in pairs(attributes) do
		if coordNames[k] then attributes[k] = mCeil(v) end
	end
	local shapes = GetShapes(teamID, channel)
	for i = #shapes, 1, -1 do
		local shape = shapes[i]
		local match = true
		for k, v in pairs(attributes) do
			local shapeV = shape[k]
			if v ~= shapeV then
				if type(v) == 'table' then
					if type(shapeV) == 'table' then
						for kk, vv in pairs(v) do
							if vv ~= shapeV[kk] then
								match = false
								break
							end
						end
					else
						match = false
					end
				else
					match = false
				end
			end
			if not match then
				break
			end
		end
		if match then
			EraseShape(shape.id, i)
		end
	end
end

local function EraseRectangle(x1, z1, x2, z2, color, label, filled, teamID, channel)
	EraseShapes({x1=x1, z1=z1, x2=x2, z2=z2, color=color, label=label, filled=filled}, teamID, channel)
end

local function EraseCircle(x, z, radius, color, label, filled, teamID, channel)
	EraseShapes({x=x, z=z, radius=radius, color=color, label=label, filled=filled}, teamID, channel)
end

local function EraseLine(x1, z1, x2, z2, color, label, arrow, teamID, channel)
	EraseShapes({x1=x1, z1=z1, x2=x2, z2=z2, color=color, label=label, arrow=arrow}, teamID, channel)
end

local function ErasePoint(x, z, color, label, teamID, channel)
	EraseShapes({x=x, z=z, color=color, label=label}, teamID, channel)
end

local function EraseUnit(unitID, color, label, teamID, channel)
	EraseShapes({unitID=unitID, color=color, label=label}, teamID, channel)
end

local function ClearShapes(teamID, channel)
	local shapes = GetShapes(teamID, channel)
	for i = #shapes, 1, -1 do
		local shape = shapes[i]
		EraseShape(shape.id, i)
	end
	UpdateShapesByType()
end

local function DisplayOnOff(onOff)
	displayOnOff = onOff
end

local function UpdateUnitPositions(shapes)
	for i = #shapes, 1, -1 do
		local shape = shapes[i]
		if shape.type == "unit" then
			shape.x, shape.y, shape.z = spGetUnitPosition(shape.unitID)
			if not shape.x then
				EraseShape(shape.id, i)
			end
		end
	end
end

local function InterpretStringData(data, command)
	local colorLoc
	for shapeTypeCapitalized, loc in pairs(colorLocations) do
		if string.find(command, shapeTypeCapitalized) then
			colorLoc = loc
			-- Spring.Echo(command, shapeTypeCapitalized, colorLoc)
			break
		end
	end
	local dataCount = #data
	for i = 1, #data do
		local d = data[i]
		-- Spring.Echo(i, d, "(raw)")
		if d == 'nil' then
			d = false
		elseif d == 'true' then
			d = true
		elseif d == 'false' then
			d = false
		elseif tonumber(d) then
			d = tonumber(d)
		end
		-- Spring.Echo(i, tostring(d), "(processed")
		data[i] = d
	end
	if colorLoc then
		local color = {}
		for i = 0, 3 do
			color[i+1] = data[colorLoc+i]
			if i > 0 then data[colorLoc+i] = "|REMOVE|" end
		end
		data[colorLoc] = color
	end
	local newData = {}
	local ndi = 0
	for i = 1, dataCount do
		local d = data[i]
		if d ~= "|REMOVE|" then
			ndi = ndi + 1
			newData[ndi] = d
			-- Spring.Echo(ndi, tostring(d))
		end
	end
	-- Spring.Echo(table.maxn(newData), "data fields out")
	return newData
end

local function BindCommand(command, func)
	widgetHandler:RegisterGlobal(command, func)
	commandBindings[command] = func
end

local function ExecuteCommand(command, data)
	local execFunc = commandBindings[command]
	execFunc(unpack(data, 1, table.maxn(data)))
end

function widget:Initialize()
	BindCommand("ShardDrawAddRectangle", AddRectangle)
	BindCommand("ShardDrawAddCircle", AddCircle)
	BindCommand("ShardDrawAddLine", AddLine)
	BindCommand("ShardDrawAddPoint", AddPoint)
	BindCommand("ShardDrawAddUnit", AddUnit)
	BindCommand("ShardDrawEraseShape", EraseShape)
	BindCommand("ShardDrawEraseRectangle", EraseRectangle)
	BindCommand("ShardDrawEraseCircle", EraseCircle)
	BindCommand("ShardDrawEraseLine", EraseLine)
	BindCommand("ShardDrawErasePoint", ErasePoint)
	BindCommand("ShardDrawEraseUnit", EraseUnit)
	BindCommand("ShardDrawClearShapes", ClearShapes)
	BindCommand("ShardDrawDisplay", DisplayOnOff)
	myFont = glLoadFont('LuaUI/Fonts/FreeSansBold.otf', 16, 4, 5)
	myMonoFont = glLoadFont('LuaUI/Fonts/DejaVuSansMono-Bold.ttf', 16, 4, 5)
	-- myFont:SetAutoOutlineColor(true)
end

function widget:GameFrame(frameNum)
	local buff = io.open('sharddrawbuffer', 'r')
	if buff then
		for line in buff:lines() do
			if line and line ~= '' and line ~= ' ' then
				widget:RecvSkirmishAIMessage(nil, line)
			end
		end
		buff:close()
	end
	local buffClear = io.open('sharddrawbuffer', 'w')
	if buffClear then
		buffClear:write(' ')
		buffClear:close()
	end
	if shapeCount == 0 or not displayOnOff or not selectedTeamID or not selectedChannel then
		return
	end
	local shapes = GetShapes(selectedTeamID, selectedChannel)
	UpdateUnitPositions(shapes)
end

function widget:RecvSkirmishAIMessage(teamID, dataStr)
	dataStr = trim(dataStr)
	if dataStr:sub(1,9) == 'ShardDraw' then
		local data = split(dataStr, '|')
		local command = tRemove(data, 1)
		-- Spring.Echo(command)
		data = InterpretStringData(data, command)
		ExecuteCommand(command, data)
	end
end

function widget:KeyPress(key, mods, isRepeat)
	-- Spring.Echo(key, mods, isRepeat)
	if shapeCount == 0 or not displayOnOff then
		return
	end
	if key > 47 and key < 58 then
		local number  = 0
		if key > 48 then
			number = key - 48
		end
		if lastKey == 99 and number > 0 then -- c
			selectedChannel = number
			UpdateShapesByType()
		elseif lastKey == 116 then -- t
			selectedTeamID = number
			UpdateShapesByType()
		end
	end
	lastKey = key
	UpdateInterface()
end

function widget:Update()
	if shapeCount == 0 or not displayOnOff then
		return
	end
	-- local camState = spGetCameraState()
	-- if not CameraStatesMatch(camState, lastCamState) then
		-- UpdateLabels()
	-- end
	selectedTeamID = selectedTeamID or lastTeamID
	selectedChannel = selectedChannel or lastChannel
	if not selectedTeamID or not selectedChannel then
		return
	end
	local shapes = GetShapes(selectedTeamID, selectedChannel)
	if needUpdateRectangles then
		rectangleDisplayList = glCreateList(DrawRectangles, shapes)
		needUpdateRectangles = false
	end
	if needUpdateCircles then
		circleDisplayList = glCreateList(DrawCircles, shapes)
		needUpdateCircles = false
	end
	if needUpdateLines then
		lineDisplayList = glCreateList(DrawLines, shapes)
		needUpdateLines = false
	end
	if needUpdatePoints then
		pointDisplayList = glCreateList(DrawPoints, shapes)
		needUpdatePoints = false
	end
	-- if needUpdateLabels then
		-- labelDisplayList = glCreateList(DrawLabels, shapes)
		-- needUpdateLabels = false
	-- end
	if needUpdateInterface then
		interfaceDisplayList = glCreateList(DrawInterface)
		needUpdateInterface = false
	end
	lastCamState = camState
end

function widget:DrawWorldPreUnit()
	if shapeCount == 0 or not displayOnOff or not selectedTeamID or not selectedChannel then
		return
	end
	glCallList(rectangleDisplayList)
	glCallList(circleDisplayList)
	glCallList(lineDisplayList)
	glCallList(pointDisplayList)
end

function widget:DrawWorld()
	if shapeCount == 0 or not displayOnOff or not selectedTeamID or not selectedChannel then
		return
	end
	local shapes = GetShapes(selectedTeamID, selectedChannel)
	DrawUnits(shapes)
end

function widget:DrawScreen()
	if shapeCount == 0 or not displayOnOff or not selectedTeamID or not selectedChannel then
		return
	end
	-- glCallList(labelDisplayList)
	local shapes = GetShapes(selectedTeamID, selectedChannel)
	DrawLabels(shapes)
	glCallList(interfaceDisplayList)
end