require "unitlists"

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
	self.reclaiming = false
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
	if unit.engineID == self.unit.engineID then

	end
end

function ReclaimBehaviour:Update()
	local f = game:Frame()
	if f % 120 == 0 then
		local doreclaim = false
		if reclaimerList[self.name] then
			doreclaim = true
		elseif ai.conCount > 2 and ai.needToReclaim then
			if ai.extraReclaimerCount == 0 then
				ai.extraReclaimerCount = 1
				self.extraReclaimer = true
				doreclaim = true
			elseif self.extraReclaimer then
				doreclaim = true
			end
		elseif ai.extraReclaimerCount == 1 and self.extraReclaimer and not ai.needToReclaim then
			ai.extraReclaimerCount = 0
			self.extraReclaimer = false
		end
		if doreclaim then
			self:Retarget()
			self:Reclaim()
		end
	end
end

function ReclaimBehaviour:Retarget()
	EchoDebug("needs target")
	local u = self.unit:Internal()
	local bestCell = ai.targethandler:GetBestReclaimCell(u)
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
		local mtype = unitTable[self.name].mtype
		if mtype == "veh" or mtype == "bot" or mtype == "amp" or mtype == "hov" then
			vulnerable = cell.groundVulnerable
		end
		if not vulnerable and (mtype == "sub" or mtype == "amp" or mtype == "shp" or mtype == "hov") then
			vulnerable = cell.submergedVulnerable
		end
		if not vulnerable and (mtype == "air") then
			vulnerable = cell.airVulnerable
		end
		if vulnerable ~= nil then
			EchoDebug("reclaiming enemy...")
			self.unit:Internal():Reclaim(vulnerable)
		elseif not ai.needToReclaim and reclaimerList[self.name] then
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