shard_include "common"

local DebugEnabled = false


local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("CleanerBehaviour: " .. inStr)
	end
end

function IsCleaner(unit)
	local tmpName = unit:Internal():Name()
	return (cleanerList[tmpName] or 0) > 0
end

CleanerBehaviour = class(Behaviour)

function CleanerBehaviour:Init()
	self.name = self.unit:Internal():Name()
	EchoDebug("init " .. self.name)
	if nanoTurretList[self.name] then
		self.isStationary = true
		self.cleaningRadius = 390
	else
		self.cleaningRadius = 300
	end
	self.ignore = {}
	self.frameCounter = 0
end

function CleanerBehaviour:Update()
	self.frameCounter = self.frameCounter + 1
	if (self.isStationary and self.frameCounter == 30) or (not self.isStationary and self.frameCounter == 90) then
		self.frameCounter = 0
		self:Search()
		self.unit:ElectBehaviour()
	end
end

function CleanerBehaviour:UnitIdle(unit)
	if unit.engineID ~= self.unit.engineID then
		return
	end
	EchoDebug("idle " .. self.unit:Internal():Name())
	self:Search()
	self.unit:ElectBehaviour()
end

function CleanerBehaviour:UnitDestroyed(unit)
	self.ignore[unit:ID()] = nil
end

function CleanerBehaviour:Activate()
	CustomCommand(self.unit:Internal(), CMD_RECLAIM, {self.cleanThis:ID()})
	-- self.ai.cleanhandler:UnitDestroyed(self.cleanThis)
end

function CleanerBehaviour:Priority()
	if self.cleanThis then
		return 103
	else
		return 0
	end
end

function CleanerBehaviour:Search()
	self.cleanThis = nil
	local cleanables = self.ai.cleanhandler:GetCleanables()
	if cleanables and #cleanables > 0 then
		local myPos = self.unit:Internal():GetPosition()
		for i = #cleanables, 1, -1 do
			local cleanable = cleanables[i]
			if not self.ignore[cleanable:ID()] then
				local p = cleanable:GetPosition()
				if p then
					local dist = Distance(myPos, p)
					if dist < self.cleaningRadius then
						self.cleanThis = cleanable
						return
					elseif self.isStationary then
						self.ignore[cleanable:ID()] = true
					end
				else
					self.ai.cleanhandler:RemoveCleanable(cleanable:ID())
				end
			end
		end
	end
end