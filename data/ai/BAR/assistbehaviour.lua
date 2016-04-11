-- require "taskqueues"
shard_include("common")

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("AssistBehaviour: " .. inStr)
	end
end

local CMD_GUARD = 25
local CMD_PATROL = 15

AssistBehaviour = class(Behaviour)

function AssistBehaviour:DoIAssist()
	if ai.nonAssistant[self.id] ~= true or self.isNanoTurret then
		return true
	else
		return false
	end
end

function AssistBehaviour:Init()
	self.active = false
	self.target = nil
	-- keeping track of how many of each type of unit
	local uname = self.unit:Internal():Name()
	self.name = uname
	if nanoTurretList[uname] then self.isNanoTurret = true end
	if commanderList[uname] then self.isCommander = true end
	self.id = self.unit:Internal():ID()
	ai.assisthandler:AssignIDByName(self)
	EchoDebug(uname .. " " .. ai.IDByName[self.id])
	EchoDebug("AssistBehaviour: added to unit "..uname)
end

function AssistBehaviour:UnitBuilt(unit)
	if unit.engineID == self.unit.engineID then
		if self.isNanoTurret then
			-- set nano turrets to patrol
			local upos = RandomAway(self.unit:Internal():GetPosition(), 50)
			local floats = api.vectorFloat()
			-- populate with x, y, z of the position
			floats:push_back(upos.x)
			floats:push_back(upos.y)
			floats:push_back(upos.z)
			self.unit:Internal():ExecuteCustomCommand(CMD_PATROL, floats)
		end
	end
end

function AssistBehaviour:UnitIdle(unit)
	if unit.engineID == self.unit.engineID then
		self.patroling = false
		self.assisting = nil
	end
end

function AssistBehaviour:Update()
	-- nano turrets don't need updating, they already have a patrol order
	if self.isNanoTurret then return end

	local f = game:Frame()

	if math.mod(f,180) == 0 then
		local unit = self.unit:Internal()
		local uname = self.name
		if self.isCommander then
			-- turn commander into build assister if you control more than half the mexes or if it's damaged
			if ai.nonAssistant[self.id] then
				if (IsSiegeEquipmentNeeded() or unit:GetHealth() < unit:GetMaxHealth() * 0.9) and ai.factories ~= 0 and ai.conCount > 2 then
					ai.nonAssistant[self.id] = nil
					self.unit:ElectBehaviour()
				end
			else
				-- switch commander back to building
				if (not IsSiegeEquipmentNeeded() and unit:GetHealth() >= unit:GetMaxHealth() * 0.9) or ai.factories == 0 or ai.conCount <= 2 then
					ai.nonAssistant[self.id] = true
					self.unit:ElectBehaviour()
				end
			end
		else
			-- fill empty spots after con units die
			if ai.IDByName[self.id] > ai.nameCount[uname] then
				EchoDebug("filling empty spots with " .. uname .. " " .. ai.IDByName[self.id])
				ai.assisthandler:AssignIDByName(self)
				EchoDebug("ID now: " .. ai.IDByName[self.id])
				self.unit:ElectBehaviour()
			end
		end
	end

	if math.mod(f,60) == 0 then
		if self.active then
			if self.target ~= nil then
				if self.assisting ~= self.target then
					local floats = api.vectorFloat()
					floats:push_back(self.target)
					self.unit:Internal():ExecuteCustomCommand(CMD_GUARD, floats)
					self.assisting = self.target
					self.patroling = false
				end
			elseif not self.patroling then
				local patrolPos = self.fallbackPos or self.unit:Internal():GetPosition()
				local pos = RandomAway(patrolPos, 200)
				local floats = api.vectorFloat()
				-- populate with x, y, z of the position
				floats:push_back(pos.x)
				floats:push_back(pos.y)
				floats:push_back(pos.z)
				self.unit:Internal():ExecuteCustomCommand(CMD_PATROL, floats)
				ai.assisthandler:AddFree(self)
				self.patroling = true
			end
		end
	end
end

function AssistBehaviour:Activate()
	EchoDebug("AssistBehaviour: activated on unit "..self.name)
	if self:DoIAssist() then
		ai.assisthandler:Release(self.unit:Internal())
		ai.assisthandler:AddFree(self)
	end
	self.active = true
	self.target = nil
end

function AssistBehaviour:Deactivate()
	EchoDebug("AssistBehaviour: deactivated on unit "..self.name)
	ai.assisthandler:RemoveWorking(self)
	ai.assisthandler:RemoveFree(self)
	self.active = false
	self.target = nil
	self.assisting = nil
end

function AssistBehaviour:Priority()
	if self:DoIAssist() then
		return 100
	else
		return 0
	end
end

function AssistBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		ai.assisthandler:RemoveAssistant(self)
	end
end

function AssistBehaviour:Assign(builderID)
	self.target = builderID
	self.lastAssignFrame = game:Frame()
end

function AssistBehaviour:SetFallback(position)
	self.fallbackPos = position
end

-- assign if not busy (used by factories to occupy idle assistants)
function AssistBehaviour:SoftAssign(builderID)
	if self.target == nil then
		self.target = builderID
	else
		if self.lastAssignFrame == nil then
			self.target = builderID
		else
			local f = game:Frame()
			if f > self.lastAssignFrame + 900 then
				self.target = builderID
			end
		end
	end
end