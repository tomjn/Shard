require "common"

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
		self.id = self.unit:Internal():ID()
		self.repairedBy = ai.buildsitehandler:ResurrectionRepairedBy(self.id)
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

	if self.repairedBy then
		if self.fresh then
			if f % 30 == 0 then
				if self.unit:Internal():GetHealth() == self.unit:Internal():GetMaxHealth() then
					self.fresh = nil
					self.repairedBy:ResurrectionComplete()
					self.unit:ElectBehaviour()
				end
			end
		end
		return
	end

	if self.fresh then
		if f % 30 == 0 then
			local u = self.unit:Internal()
			if not u:IsBeingBuilt() then
				local pos = u:GetPosition()
				local dist = Distance(pos, self.initialPosition)
				if dist >= 50 then
					self.fresh = nil
					self.unit:ElectBehaviour()
				end
			end
		end
	else
		if f % 150 == 0 then
			-- units (especially construction units) can still get stuck in factories long after they're built
			local u = self.unit:Internal()
			if not u:IsBeingBuilt() then
				local pos = u:GetPosition()
				local dist = Distance(pos, self.initialPosition)
				if dist < 50 then
					self.fresh = true
					self.unit:ElectBehaviour()
				end
			end
		end
	end
end

function ExitFactoryBehaviour:Activate()
	self.active = true
	if self.repairedBy then
		-- stay here
	else
		local u = self.unit:Internal()
		local pos = u:GetPosition()
		local out = api.Position()
		out.x = pos.x
		out.y = pos.y
		out.z = pos.z + 200
		if out.z > ai.maxElmosZ - 1 then
			out.z = ai.maxElmosZ - 1
		end
		u:Move(out)
		self.lastOrderFrame = game:Frame()
	end
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
	if unit.engineID == self.unit.engineID then
		ai.buildsitehandler:RemoveResurrectionRepairedBy(self.id)
	end
end
