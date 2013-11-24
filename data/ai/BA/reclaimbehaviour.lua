require "common"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("ReclaimBehaviour: " .. inStr)
	end
end

local CMD_RESURRECT = 125

function IsReclaimer(unit)
	local tmpName = unit:Internal():Name()
	return (reclaimerList[tmpName] or 0) > 0
end

ReclaimBehaviour = class(Behaviour)

function ReclaimBehaviour:Init()
	local mtype, network = ai.maphandler:MobilityOfUnit(self.unit:Internal())
	self.mtype = mtype
	self.name = self.unit:Internal():Name()
	if reclaimerList[self.name] then self.dedicated = true end
	self.id = self.unit:Internal():ID()
end

function ReclaimBehaviour:UnitBuilt(unit)
	if unit.engineID == self.unit.engineID then
		EchoDebug("got new reclaimer")
	end
end

function ReclaimBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		-- notify the command that area is too hot
		-- game:SendToConsole("reclaimer " .. self.name .. " died")
		if self.target then
			ai.targethandler:AddBadPosition(self.target, self.mtype)
		end
	end
end

function ReclaimBehaviour:UnitIdle(unit)
	--[[
	if unit.engineID == self.unit.engineID then
		self.targetcell = nil
		self.unit:ElectBehaviour()
	end
	]]--
end

function ReclaimBehaviour:Update()
	local f = game:Frame()
	if f % 120 == 0 then
		local doreclaim = false
		if self.dedicated then
			doreclaim = true
		elseif ai.conCount > 2 and ai.needToReclaim and ai.reclaimerCount == 0 and ai.IDByType[self.id] ~= 1 and ai.IDByType[self.id] ~= 3 then
			if not ai.haveExtraReclaimer then
				ai.haveExtraReclaimer = true
				self.extraReclaimer = true
				doreclaim = true
			elseif self.extraReclaimer then
				doreclaim = true
			end
		else
			if self.extraReclaimer then
				ai.haveExtraReclaimer = false
				self.extraReclaimer = false
				self.targetcell = nil
				self.unit:ElectBehaviour()
			end
		end
		if doreclaim then
			self:Retarget()
			self:Reclaim()
			self.unit:ElectBehaviour()
		end
	end
end

function ReclaimBehaviour:Retarget()
	EchoDebug("needs target")
	local unit = self.unit:Internal()
	local bestCell = ai.targethandler:GetBestReclaimCell(unit)
	if bestCell then
		EchoDebug("got reclaim cell")
		self.targetcell = bestCell
	else
		self.targetcell = nil
	end
end

function ReclaimBehaviour:Priority()
	if self.targetcell ~= nil then
		EchoDebug("priority 101")
		return 101
	else
		-- EchoDebug("priority 0")
		return 0
	end
end

function ReclaimBehaviour:Reclaim()
	EchoDebug("reclaim")
	if self.targetcell ~= nil and self.active then
		local cell = self.targetcell
		self.target = cell.pos
		EchoDebug("actually reclaiming cell at" .. self.target.x .. " " .. self.target.z)
		-- find an enemy unit to reclaim if there is one
		local vulnerable
		if self.mtype == "veh" or self.mtype == "bot" or self.mtype == "amp" or self.mtype == "hov" then
			vulnerable = cell.groundVulnerable
		end
		if not vulnerable and (self.mtype == "sub" or self.mtype == "amp" or self.mtype == "shp" or self.mtype == "hov") then
			vulnerable = cell.submergedVulnerable
		end
		if not vulnerable and (self.mtype == "air") then
			vulnerable = cell.airVulnerable
		end
		if vulnerable ~= nil then
			EchoDebug("reclaiming enemy...")
			self.unit:Internal():Reclaim(vulnerable)
		elseif not ai.needToReclaim and self.dedicated then
			EchoDebug("resurrecting...")
			local floats = api.vectorFloat()
			floats:push_back(self.target.x)
			floats:push_back(self.target.y)
			floats:push_back(self.target.z)
			self.unit:Internal():ExecuteCustomCommand(CMD_RESURRECT, floats)
		else
			EchoDebug("reclaiming area...")
			self.unit:Internal():AreaReclaim(self.target, 360)
		end
	end
end

function ReclaimBehaviour:Activate()
	EchoDebug("activate")
	self.active = true
end

function ReclaimBehaviour:Deactivate()
	EchoDebug("deactivate")
	self.active = false
end