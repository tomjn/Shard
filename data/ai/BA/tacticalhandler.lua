shard_include "common"

-- keeps track of where enemy units seem to be moving

local DebugEnabled = false
local debugPlotTacticalFile


local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("TacticalHandler: " .. inStr)
	end
end

local function PlotDebug(x1, z1, vx, vz, label)
	if DebugEnabled then
		local x2 = x1 + vx * 1200
		local z2 = z1 + vz * 1200
		debugPlotTacticalFile:write(ceil(x1) .. " " .. ceil(z1) .. " " .. ceil(x2) .. " " .. ceil(z2) .. " " .. label .. "\n")
	end
end

TacticalHandler = class(Module)

function TacticalHandler:Name()
	return "TacticalHandler"
end

function TacticalHandler:internalName()
	return "tacticalhandler"
end

function TacticalHandler:Init()
	self.lastPositionsFrame = 0
	self.lastAverageFrame = 0
	self.lastPositions = {}
	self.lastKnownPositions = {}
	self.lastKnownVectors = {}
	self.unitSamples = {}
	self.threatLayerNames = { "ground", "air", "submerged" }
	ai.incomingThreat = 0
	if DebugEnabled then debugPlotTacticalFile = assert(io.open("debugtacticalplot",'w'), "Unable to write debugtacticalplot") end
end

function TacticalHandler:NewEnemyPositions(positions)
	local f = game:Frame()
	local since = f - self.lastPositionsFrame
	local update = {}
	for i, e in pairs(positions) do
		local le = self.lastPositions[e.unitID]
		if le then
			local vx = e.position.x - le.position.x
			local vz = e.position.z - le.position.z
			if abs(vx) > 0 or abs(vz) > 0 then
				vx = vx / since
				vz = vz / since
				if not self.unitSamples[e.unitID] then
					self.unitSamples[e.unitID] = {}
				end
				table.insert(self.unitSamples[e.unitID], { vx = vx, vz = vz })
			end
			self.lastKnownPositions[e.unitID] = e
		end
		update[e.unitID] = e
	end
	self.lastPositions = update
	self.lastPositionsFrame = f
	self:AverageSamples()
end

function TacticalHandler:AverageUnitSamples(samples)
	local totalVX = 0
	local totalVZ = 0
	for i, sample in pairs(samples) do
		totalVX = totalVX + sample.vx
		totalVZ = totalVZ + sample.vz
	end
	local vx = totalVX / #samples
	local vz = totalVZ / #samples
	return vx, vz
end

function TacticalHandler:AverageSamples()
	local f = game:Frame()
	local since = f - self.lastAverageFrame
	if since < 300 then return end
	if DebugEnabled then debugPlotTacticalFile:close() end
	if DebugEnabled then debugPlotTacticalFile = assert(io.open("debugtacticalplot",'w'), "Unable to write debugtacticalplot") end
	-- ai.turtlehandler:ResetThreatForecast()
	for unitID, samples in pairs(self.unitSamples) do
		local e = self.lastKnownPositions[unitID]
		if e then
			local vx, vz = self:AverageUnitSamples(samples)
			self.lastKnownVectors[unitID] = { vx = vx, vz = vz } -- so that anyone using this unit table as a target will be able to lead a little
			PlotDebug(e.position.x, e.position.z, vx, vz, "THREAT")
			-- ai.turtlehandler:AddThreatVector(e, vx, vz)
		end
	end
	-- ai.turtlehandler:AlertDangers()
	self.unitSamples = {}
	self.lastAverageFrame = f
end

-- for raider and other targetting export
function TacticalHandler:PredictPosition(unitID, frames)
	local vector = self.lastKnownVectors[unitID]
	if vector == nil then return end
	local e = self.lastKnownPositions[unitID]
	if e == nil then return end
	return ApplyVector(e.position.x, e.position.z, vector.vx, vector.vz, frames)
end

-- so our tables don't bloat
function TacticalHandler:UnitDead(unit)
	local unitID = unit:ID()
	self.lastKnownPositions[unitID] = nil
	self.lastKnownVectors[unitID] = nil
	self.unitSamples[unitID] = nil
end

function TacticalHandler:PlotPositionDebug(position, label)
	if DebugEnabled then
		debugPlotTacticalFile:write(ceil(position.x) .. " " .. ceil(position.z) .. " " .. label .. "\n")
	end
end

function TacticalHandler:PlotABDebug(x1, z1, x2, z2, label)
	if DebugEnabled then
		debugPlotTacticalFile:write(ceil(x1) .. " " .. ceil(z1) .. " " .. ceil(x2) .. " " .. ceil(z2) .. " " .. label .. "\n")
	end
end