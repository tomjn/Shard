require "common"

local DebugEnabled = true
local debugPlotTacticalFile

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("TacticalHandler: " .. inStr)
	end
end

local function PlotDebug(x1, z1, vx, vz, label)
	if DebugEnabled then
		local x2 = x1 + vx * 900
		local z2 = z1 + vz * 900
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
	self.unitSamples = {}
	self.threatLayerNames = { "ground", "air", "submerged" }
	ai.enemyMovement = { x = 0, z = 0, vx = 0, vz = 0 }
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
	if DebugEnabled then debugPlotTacticalFile = assert(io.open("debugtacticalplot",'w'), "Unable to write debugtacticalplot") end
	for unitID, samples in pairs(self.unitSamples) do
		local e = self.lastKnownPositions[unitID]
		if e then
			local vx, vz = self:AverageUnitSamples(samples)
			PlotDebug(e.position.x, e.position.z, vx, vz, unitID)
		end
	end
	self.unitSamples = {}
	self.lastAverageFrame = f
	if DebugEnabled then debugPlotTacticalFile:close() end
end