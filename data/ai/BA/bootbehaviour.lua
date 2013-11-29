require "common"

BootBehaviour = class(Behaviour)

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("BootBehaviour: " .. inStr)
	end
end

local CMD_MOVE_STATE = 50
local MOVESTATE_HOLDPOS = 0

function BootBehaviour:Init()
	self.id = self.unit:Internal():ID()
	self.name = self.unit:Internal():Name()
	self.mobile = not unitTable[self.name].isBuilding
	self.mtype = unitTable[self.name].mtype
	self.lastInFactoryCheck = game:Frame()
	self:FindMyFactory()
	self.repairedBy = ai.buildsitehandler:ResurrectionRepairedBy(self.id)
	if self.repairedBy or self.factory then
		if not self.repairedBy and (self.mtype == "air" or commanderList[self.name]) then
			-- air units and commanders don't need to leave the factory
		else
			self.fresh = true
		end
	end
	self.unit:ElectBehaviour()
end

function BootBehaviour:UnitCreated(unit)

end

function BootBehaviour:UnitIdle(unit)

end

function BootBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		self.fresh = nil
	end
end

function BootBehaviour:Update()
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

	if not self.mobile then return end

	if self.fresh then
		if f % 30 == 0 then
			local u = self.unit:Internal()
			if not u:IsBeingBuilt() then
				local pos = u:GetPosition()
				-- EchoDebug(pos.x .. " " .. pos.z .. " " .. self.factory.exitRect.x1 .. " " .. self.factory.exitRect.z1 .. " " .. self.factory.exitRect.x2 .. " " .. self.factory.exitRect.z2)
				if not PositionWithinRect(pos, self.factory.exitRect) then
					self.fresh = nil
					self.unit:ElectBehaviour()
				elseif self.active and self.lastOrderFrame and self.lastExitSide then
					-- fifteen seconds after the first attempt, try a different side
					if f > self.lastOrderFrame + 450 then
						if self.factory.sides ~= 1 then
							if self.factory.sides == 2 then
								self:ExitFactory("north")
							elseif self.factory.sides == 3 then
								if self.lastExitSide == "south" then
									self:ExitFactory("east")
								elseif self.lastExitSide == "east" then
									self:ExitFactory("west")
								end
							elseif self.factory.sides == 4 then
								if self.lastExitSide == "south" then
									self:ExitFactory("north")
								elseif self.lastExitSide == "north" then
									self:ExitFactory("east")
								elseif self.lastExitSide == "east" then
									self:ExitFactory("west")
								end
							end
						end
					end
				end
			end
		end
	else
		if f > self.lastInFactoryCheck + 150 then
			-- units (especially construction units) can still get stuck in factories long after they're built
			local u = self.unit:Internal()
			if not u:IsBeingBuilt() then
				self:FindMyFactory()
				if self.factory then
					EchoDebug(self.name .. " is in a factory")
					self.fresh = true
					self.unit:ElectBehaviour()
					return
				end
			end
			self.lastInFactoryCheck = f
		end
	end
end

function BootBehaviour:Activate()
	EchoDebug("activated on " .. self.name)
	self.active = true
	if self.repairedBy then
		self:SetMoveState()
	else
		self:ExitFactory("south")
	end
end

function BootBehaviour:Deactivate()
	EchoDebug("deactivated on " .. self.name)
	self.active = false
end

function BootBehaviour:Priority()
	if self.fresh and self.mobile then
		return 120
	else
		return 0
	end
end

function BootBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		ai.buildsitehandler:RemoveResurrectionRepairedBy(self.id)
	end
end

-- set to hold position while being repaired after resurrect
function BootBehaviour:SetMoveState()
	local thisUnit = self.unit
	if thisUnit then
		local floats = api.vectorFloat()
		floats:push_back(MOVESTATE_HOLDPOS)
		thisUnit:Internal():ExecuteCustomCommand(CMD_MOVE_STATE, floats)
	end
end

function BootBehaviour:FindMyFactory()
	local pos = self.unit:Internal():GetPosition()
	for level, factories in pairs(ai.factoriesAtLevel) do
		for i, factory in pairs(factories) do
			if PositionWithinRect(pos, factory.exitRect) then
				self.factory = factory
				return
			end
		end
	end
	self.factory = nil
end

function BootBehaviour:ExitFactory(side)
		local outX, outZ
		if side == "south" then
			outX = 0
			outZ = 200
		elseif side == "north" then
			outX = 0
			outZ = -200
		elseif side == "east" then
			outX = 200
			outZ = 0
		elseif side == "west" then
			outX = -200
			outZ = 0
		end
		local u = self.unit:Internal()
		local pos = self.factory.position
		local out = api.Position()
		out.x = pos.x
		out.y = pos.y + outX
		out.z = pos.z + outZ
		if out.x > ai.maxElmosX - 1 then
			out.x = ai.maxElmosX - 1
		elseif out.x < 1 then
			out.x = 1
		end
		if out.z > ai.maxElmosZ - 1 then
			out.z = ai.maxElmosZ - 1
		elseif out.z < 1 then
			out.z = 1
		end
		u:Move(out)
		self.lastOrderFrame = game:Frame()
		self.lastExitSide = side
end