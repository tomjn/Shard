require "common"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("RaiderBehaviour: " .. inStr)
	end
end

local CMD_IDLEMODE = 145
local CMD_MOVE_STATE = 50
local MOVESTATE_HOLDPOS = 0
local MOVESTATE_ROAM = 2

function IsRaider(unit)
	for i,name in ipairs(raiderList) do
		if name == unit:Internal():Name() then
			return true
		end
	end
	return false
end

RaiderBehaviour = class(Behaviour)

function RaiderBehaviour:Init()
	local mtype, network = ai.maphandler:MobilityOfUnit(self.unit:Internal())
	self.mtype = mtype
	self.name = self.unit:Internal():Name()
	if ai.raiderCount[mtype] == nil then
		ai.raiderCount[mtype] = 1
	else
		ai.raiderCount[mtype] = ai.raiderCount[mtype] + 1
	end
end

function RaiderBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		-- game:SendToConsole("raider " .. self.name .. " died")
		if self.target then
			ai.targethandler:AddBadPosition(self.target, self.mtype)
		end
		ai.raidhandler:NeedLess(self.mtype)
		ai.raiderCount[self.mtype] = ai.raiderCount[self.mtype] - 1
	end
end

function RaiderBehaviour:UnitIdle(unit)
	if unit.engineID == self.unit.engineID then
		self.target = nil
		self.evading = false
		-- keep planes from landing (i'd rather set land state, but how?)
		if self.mtype == "air" then
			unit:Internal():Move(RandomAway(unit:Internal():GetPosition(), 500))
		end
		self.unit:ElectBehaviour()
	end
end

function RaiderBehaviour:RaidCell(cell, mtype)
	if self.unit == nil then
		EchoDebug("no raider unit to raid cell with!")
		-- ai.raidhandler:RemoveRecruit(self)
	elseif self.unit:Internal() == nil then 
		EchoDebug("no raider unit internal to raid cell with!")
		-- ai.raidhandler:RemoveRecruit(self)
	else
		local utable = unitTable[self.name]
		if mtype == "sub" then
			range = utable.submergedRange
		else
			range = utable.groundRange
		end
		self.target = RandomAway(cell.pos, range * 0.5)
		if mtype == "air" then
			self.unitTarget = cell.airTarget
		end
		if self.active then
			if mtype == "air" then
				if self.unitTarget ~= nil then
					self.unit:Internal():Attack(self.unitTarget)
				end
			else
				self.unit:Internal():Move(self.target)
			end
		end
		self.unit:ElectBehaviour()
	end
end

function RaiderBehaviour:Priority()
	if not self.target then
		-- revert to scouting
		return 0
	else
		return 100
	end
end

function RaiderBehaviour:Activate()
	self.active = true
	if self.target then
		if self.mtype == "air" then
			if self.unitTarget ~= nil then
				self.unit:Internal():Attack(self.unitTarget)
			end
		else
			self.unit:Internal():Move(self.target)
		end
	end
end

function RaiderBehaviour:Deactivate()
	self.active = false
	self.target = nil
end

function RaiderBehaviour:Update()
	local f = game:Frame()

	if not self.active then
		if math.mod(f, 89) == 0 then
			local unit = self.unit:Internal()
			local bestCell = ai.targethandler:GetBestRaidCell(unit)
			if bestCell then
				self:RaidCell(bestCell)
			else
				self.target = nil
				self.unit:ElectBehaviour()
				-- revert to scouting
			end
		end
	else
		if math.mod(f, 29) == 0 then
			-- attack nearby vulnerables immediately
			local unit = self.unit:Internal()
			local attackTarget
			if ai.targethandler:IsSafePosition(unit:GetPosition(), unit, 1) then
				attackTarget = ai.targethandler:NearbyVulnerable(unit)
			end
			if attackTarget then
				unit:Attack(attackTarget)
			else
				-- evade enemies on the way to the target, if possible
				if self.target ~= nil then
					local newPos, arrived = ai.targethandler:BestAdjacentPosition(unit, self.target)
					if newPos then
						EchoDebug("raider evading")
						unit:Move(newPos)
						self.evading = true
					elseif arrived then
						EchoDebug("raider arrived")
						-- if we're at the target
						self.evading = false
					elseif self.evading then
						EchoDebug("raider setting course to taget")
						-- return to course to target after evading
						if self.mtype == "air" then
							if self.unitTarget ~= nil then
								self.unit:Internal():Attack(self.unitTarget)
							end
						else
							self.unit:Internal():Move(self.target)
						end
						self.evading = false
					end
				end
			end
		end
	end
end

function RaiderBehaviour:SetMoveState()
	local thisUnit = self.unit
	if thisUnit then
		local unitName = thisUnit:Internal():Name()
		if holdPositionList[unitName] then
			local floats = api.vectorFloat()
			floats:push_back(MOVESTATE_HOLDPOS)
			thisUnit:Internal():ExecuteCustomCommand(CMD_MOVE_STATE, floats)
		end
		if roamList[unitName] then
			local floats = api.vectorFloat()
			floats:push_back(MOVESTATE_ROAM)
			thisUnit:Internal():ExecuteCustomCommand(CMD_MOVE_STATE, floats)
		end
		if self.mtype == "air" then
			local floats = api.vectorFloat()
			floats:push_back(1)
			thisUnit:Internal():ExecuteCustomCommand(CMD_IDLEMODE, floats)
		end
	end
end