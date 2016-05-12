function widget:GetInfo()
	return {
		name	= "Shard Help: Debug Visualizer",
		desc	= "plots stuff dumped to debugplots",
		author	= "eronoobos",
		date 	= "November 28, 2013",
		license	= "whatever",
		layer 	= 0,
		enabled	= false
	}
end

local squares = {}
local points = {}

local colors = {}
colors["veh"] = { 1, 0, 0 }
colors["bot"] = { 1, 0.5, 0 }
colors["amp"] = { 0, 1, 0 }
colors["hov"] = { 0, 1, 1 }
colors["shp"] = { 0.5, 0.5, 1 }
colors["sub"] = { 0, 0, 1 }
colors["start"] = { 1, 1, 1 }
colors["1"] = { 1, 1, 0 }
colors["2"] = { 0, 0, 1 }
colors["3"] = { 1, 0, 0 }
colors["JAM"] = { 0, 0, 0 }
colors["known"] = { 1, 1, 1 }
colors["NOBUILD"] = { 1, 0, 0 }
colors["PLAN"] = { 0, 1, 0 }
colors["LIMB"] = { 0.5, 0, 0 }


local mtypes = { "veh", "bot", "amp", "hov", "shp", "sub" }
local ltypes = { "1", "2", "3" }

local mt = 0
local mtype
local lt = 0

local inputFilename

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

function widget:GameFrame(frameNum)
	if inputFilename == nil then return end
	if mtype == nil then return end
	if frameNum % 30 ~= 0 then return end
	local maxV = 0
	local minV = 10000
	io.input(inputFilename)
	squares = {}
	points = {}
	while true do
		local line = io.read()
		if line == nil then break end
		local w = split(line, " ")
		if #w == 3 then
			if w[3] == mtype or w[3] == "start" or w[3] == "known" then
				local color = colors[w[3]]
				-- Spring.MarkerAddPoint(w[1], 0, w[2] , w[3])
				table.insert(points, {x = w[1], z = w[2],  y = Spring.GetGroundHeight(w[1], w[2]), label = w[3], color = color})
			else
				if colors[w[3]] then color = colors[w[3]] else color = { 1, 1, 1 } end
				table.insert(points, {x = w[1], z = w[2], y = Spring.GetGroundHeight(w[1], w[2]), label = w[3], color = color})
			end
		elseif #w == 4 then
			if w[4] == mtype or (mtype == "LOS" and (w[4] == "1" or w[4] == "2" or w[4] == "3" or w[4] == "JAM")) then
				-- Spring.MarkerAddLine(w[1], 500, w[2], w[3], 500, w[4])
				local halfsize = w[3] / 2
				local color = colors[w[4]]
				-- if #squares < 10 then Spring.MarkerAddPoint(w[1], 0, w[2] , w[4]) end
				table.insert(squares, {x = w[1], z = w[2], y = Spring.GetGroundHeight(w[1], w[2]), size = w[3], x1 = w[1] - halfsize, z1 = w[2] - halfsize, x2 = w[1] + halfsize, z2 = w[2] + halfsize, color = color})
			elseif mtype == "TARGET" then
				local v = tonumber(w[4])
				if v > maxV then maxV = v end
				if v < minV then minV = v end
				local halfsize = w[3] / 2
				table.insert(squares, {x = w[1], z = w[2], y = Spring.GetGroundHeight(w[1], w[2]), size = w[3], x1 = w[1] - halfsize, z1 = w[2] - halfsize, x2 = w[1] + halfsize, z2 = w[2] + halfsize, color = nil, v = v})
			end
		elseif #w == 5 then
			local sx = (w[3] - w[1]) / 2
			local sz = (w[4] - w[2]) / 2
			local size = math.max(sx, sz)
			local x = w[1] + sx
			local z = w[2] + sz
			local color = colors[w[5]]
			table.insert(squares, {x = x, y = Spring.GetGroundHeight(x, z), z = z, size = size, color = color, x1 = w[1], z1 = w[2], x2 = w[3], z2 = w[4] })
		end
	end
	io.close()
	if mtype == "TARGET" then
		for i, s in pairs(squares) do
			local r = 0
			local g = 0
			if s.v > 0 then
				g = (s.v / maxV) * 255
			elseif s.v < 0 then
				r = (math.abs(s.v) / math.abs(minV)) * 255
			end
			s.color = { r, g, 0 }
		end
		-- Spring.Echo("max value: ", maxV, "  mid value: ", midV, "  min value: ", minV)
	end
	-- Spring.Echo("got debug plots for " .. mtype .. ": " .. #squares .. " squares and " .. #points .. " points")
end

function widget:KeyPress(key, mods, isRepeat)
	-- 48 = 0, 57 = 9
	-- Spring.Echo(key)
	if key == 49 then
		inputFilename = "debugplot"
		mt = mt + 1
		if mt > #mtypes then mt = 1 end
		mtype = mtypes[mt]
		Spring.Echo("viewing debugplot")
	elseif key == 50 then
		inputFilename = "debuglosplot"
		mtype = "LOS"
		Spring.Echo("viewing LOS")
	elseif key == 51 then
		inputFilename = "debugtargetplot"
		mtype = "TARGET"
		Spring.Echo("viewing TARGET")
	elseif key == 52 then
		inputFilename = "debugbuildplot"
		mtype = "NOBUILD"
		Spring.Echo("viewing NOBUILD")
	elseif key == 53 then
		inputFilename = "debugturtleplot"
		mtype = "TURTLE"
		Spring.Echo("viewing TURTLE")
	end
end

local function DoLine(x1, y1, z1, x2, y2, z2)
    gl.Vertex(x1, y1, z1)
    gl.Vertex(x2, y2, z2)
end

function widget:DrawWorld()
	if #squares == 0 and #points == 0 then
		return
	end
	gl.DepthTest(false)
	gl.PushMatrix()
	gl.LineWidth(16)

	for i, s in pairs(squares) do
		if Spring.IsSphereInView(s.x, s.y, s.z, s.size) == true then
			-- gl.DrawGroundCircle(s.x, y, s.z, s.size, 4)
			gl.Color(s.color[1], s.color[2], s.color[3], 0.33)
			gl.DrawGroundQuad(s.x1, s.z1, s.x2, s.z2)
		end
	end

	for i, p in pairs(points) do
		if Spring.IsSphereInView(p.x, p.y, p.z, 64) == true then
			gl.DepthTest(false)
			gl.PushMatrix()
			if mtype ~= "TURTLE" or p.label == "LIMB" then
				gl.Color(p.color[1], p.color[2], p.color[3], 1)
				gl.DrawGroundCircle(p.x, p.y, p.z, 64, 8)
			end
			if p.label ~= "LIMB" then
				gl.Translate(p.x, p.y, p.z)
				gl.Billboard()
				gl.Color(1, 1, 1, 1)
				gl.Text(p.label, 0, 0, 64, "cdo")
			end
			gl.PopMatrix()
			gl.DepthTest(true)
		end
	end

	gl.LineWidth(1)
	gl.Color(1, 1, 1, 0.5)
	gl.PopMatrix()
	gl.DepthTest(true)
end
