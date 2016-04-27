shard_include "common"

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
	self.layers = {}
	if self.mtype == "veh" or self.mtype == "bot" or self.mtype == "amp" or self.mtype == "hov" then
		table.insert(self.layers, "ground")
	end
	if self.mtype == "sub" or self.mtype == "amp" or self.mtype == "shp" or self.mtype == "hov" then
		table.insert(self.layers, "submerged")
	end
	if self.mtype == "air" then
		table.insert(self.layers, "air")
	end
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
		ai.buildsitehandler:ClearMyPlans(self)
	end
end

function ReclaimBehaviour:UnitIdle(unit)
	--[[
	if unit.engineID == self.unit.engineID then
		self.targetCell = nil
		self.unit:ElectBehaviour()
	end
	]]--
end

function ReclaimBehaviour:Update()
	local f = game:Frame()
	if f % 120 == 0 then
		local doreclaim = false
		if self.dedicated and not self.resurrecting then
			doreclaim = true
		elseif ai.conCount > 2 and ai.needToReclaim and ai.reclaimerCount == 0 and ai.IDByName[self.id] ~= 1 and ai.IDByName[self.id] == ai.nameCount[self.name] then
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
				self.targetCell = nil
				self.unit:ElectBehaviour()
			end
		end
		if doreclaim then
			self:Retarget()
			self:Reclaim()
		end
	end
end

function ReclaimBehaviour:Retarget()
	EchoDebug("needs target")
	local unit = self.unit:Internal()
	if not ai.needToReclaim and self.dedicated then
		self.targetResurrection, self.targetCell = ai.targethandler:WreckToResurrect(unit)
	else
		self.targetCell = ai.targethandler:GetBestReclaimCell(unit)
		self.targetResurrection = nil
	end
	self.unit:ElectBehaviour()
end

function ReclaimBehaviour:Priority()
	if self.targetCell ~= nil then
		return 101
	else
		-- EchoDebug("priority 0")
		return 0
	end
end

function ReclaimBehaviour:Reclaim()
	if self.active then
		if self.targetCell ~= nil then
			local cell = self.targetCell
			self.target = cell.pos
			EchoDebug("cell at" .. self.target.x .. " " .. self.target.z)
			-- find an enemy unit to reclaim if there is one
			local vulnerable
			for i, layer in pairs(self.layers) do
				local vLayer = layer .. "Vulnerable"
				vulnerable = cell[vLayer]
				if vulnerable ~= nil then break end
			end
			if vulnerable ~= nil then
				EchoDebug("reclaiming enemy...")
				CustomCommand(self.unit:Internal(), CMD_RECLAIM, {vulnerable.unitID})
			elseif self.targetResurrection ~= nil and not self.resurrecting then
				EchoDebug("resurrecting...")
				local resPosition = self.targetResurrection.position
				local unitName = featureTable[self.targetResurrection.featureName].unitName
				EchoDebug(unitName)
				CustomCommand(self.unit:Internal(), CMD_RESURRECT, {resPosition.x, resPosition.y, resPosition.z, 15})
				ai.buildsitehandler:NewPlan(unitName, resPosition, self, true)
				self.resurrecting = true
			else
				EchoDebug("reclaiming area...")
				self.unit:Internal():AreaReclaim(self.target, 200)
			end
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
	self:ResurrectionComplete() -- so we don't get stuck
end

function ReclaimBehaviour:ResurrectionComplete()
	self.resurrecting = false
	ai.buildsitehandler:ClearMyPlans(self)
end