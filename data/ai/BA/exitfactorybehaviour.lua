require "unitlists"

ExitFactoryBehaviour = class(Behaviour)

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("ExitFactoryBehaviour: " .. inStr)
	end
end

function ExitFactoryBehaviour:Init()
end

function ExitFactoryBehaviour:UnitCreated(unit)
	if unit.engineID == self.unit.engineID then
		self.fresh = true
		self.initialPosition = self.unit:Internal():GetPosition()
		self.unit:ElectBehaviour()
	end
end

function ExitFactoryBehaviour:UnitIdle(unit)

end

function ExitFactoryBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		self.fresh = nil
	end
end

function ExitFactoryBehaviour:Update()
	local f = game:Frame()
	if self.fresh then
		if f % 10 == 0 then
			local u = self.unit:Internal()
			if not u:IsBeingBuilt() then
				local pos = u:GetPosition()
				local dist = distance(pos, self.initialPosition)
				if dist >= 50 then
					self.fresh = nil
					self.unit:ElectBehaviour()
				end
			end
		end
	else
		if f % 150 == 0 then
			local u = self.unit:Internal()
			if not u:IsBeingBuilt() then
				local pos = u:GetPosition()
				local dist = distance(pos, self.initialPosition)
				if dist < 50 then
					self.fresh = true
					self.unit:ElectBehaviour()
				else
					self.fresh = false
				end
			end
		end
	end
end

function ExitFactoryBehaviour:Activate()
	self.active = true
	local u = self.unit:Internal()
	local pos = u:GetPosition()
	pos.z = pos.z + 200
	if pos.z > ai.maxElmosZ - 1 then
		pos.z = ai.maxElmosZ - 1
	end
	u:Move(pos)
end

function ExitFactoryBehaviour:Deactivate()
	self.active = false
end

function ExitFactoryBehaviour:Priority()
	if self.fresh then
		return 120
	else
		return 0
	end
end

function ExitFactoryBehaviour:UnitDead(unit)

end
