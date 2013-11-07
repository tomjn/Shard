-- require "taskqueues"
require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("AssistBehaviour: " .. inStr)
	end
end

local IDByTypeTaken = {}
local CMD_GUARD = 25
local CMD_PATROL = 15

AssistBehaviour = class(Behaviour)

function AssistBehaviour:DoIAssist()
	if advConList[self.name] then
		return false
	elseif (self.IDByType ~= 1 and self.IDByType ~= 3) or buildAssistList[self.name] then
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
	if ai.totalCons == nil then ai.totalCons = {} end
	if ai.totalCons[uname] == nil then
		ai.totalCons[uname] = 1
	else
		ai.totalCons[uname] = ai.totalCons[uname] + 1
	end
	self:AssignIDByType()
	EchoDebug(uname .. " " .. self.IDByType)
	EchoDebug("AssistBehaviour: added to unit "..uname)
end

function AssistBehaviour:UnitBuilt(unit)
	if unit.engineID == self.unit.engineID then
		if self.name == "cornanotc" or self.name == "armnanotc" then
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
	local f = game:Frame()

	if math.mod(f,180) == 0 then
		local unit = self.unit:Internal()
		local uname = self.name
		if uname == "cornanotc" or uname == "armnanotc" then
			-- self.unit:Internal():MoveAndFire(self.unit:Internal():GetPosition())
		else
			if uname == "corcom" or uname == "armcom" then
				-- turn commander into build assister if you control more than half the mexes or if it's damaged
				if self.IDByType == 1 then
					if IsSiegeEquipmentNeeded() or unit:GetHealth() < unit:GetMaxHealth() * 0.9 then
						self.IDByType = 2
						ai.assisthandler:Release(unit)
						self.unit:ElectBehaviour()
					end
				end
			else
				-- fill empty spots after con units die
				EchoDebug(uname .. " " .. self.IDByType .. " / " .. tostring(ai.totalCons[uname]))
				if self.IDByType > ai.totalCons[uname] then
					EchoDebug("filling empty spots with " .. uname .. " " .. self.IDByType)
					self:AssignIDByType()
					EchoDebug("ID now: " .. self.IDByType)
					self.unit:ElectBehaviour()
				end
			end
		end
	end

	if math.mod(f,60) == 0 then
		if self.active and self.name ~= "cornanotc" and self.name ~= "armnanotc" then
			if self.target ~= nil then
				if self.assisting ~= self.target:ID() then
					local floats = api.vectorFloat()
					floats:push_back(self.target:ID())
					self.unit:Internal():ExecuteCustomCommand(CMD_GUARD, floats)
					self.assisting = self.target:ID()
					self.patroling = false
				end
			elseif not self.patroling then
				local upos = RandomAway(self.unit:Internal():GetPosition(), 400)
				local floats = api.vectorFloat()
				-- populate with x, y, z of the position
				floats:push_back(upos.x)
				floats:push_back(upos.y)
				floats:push_back(upos.z)
				self.unit:Internal():ExecuteCustomCommand(CMD_PATROL, floats)
				ai.assisthandler:AddFree(self)
				self.patroling = true
			end
		end
	end
end

function AssistBehaviour:Activate()
	EchoDebug("AssistBehaviour: activated on unit "..self.name)
	self.active = true
	self.target = nil
	if self:DoIAssist() then
		ai.assisthandler:AddFree(self)
	end
end

function AssistBehaviour:Deactivate()
	EchoDebug("AssistBehaviour: deactivated on unit "..self.name)
	self.active = false
	self.target = nil
	self.assisting = nil
	ai.assisthandler:RemoveFree(self)
end

function AssistBehaviour:Priority()
	if self.IDByType ~= nil then
		if self:DoIAssist() then
			return 100
		else
			return 0
		end
	elseif buildAssistList[self.name] then
		-- game:SendToConsole("nano")
		return 100
	else
		return 0
	end
end

function AssistBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		-- game:SendToConsole("assistant " .. self.name .. " died")
		local uname = self.name
		if IDByTypeTaken[uname] ~= nil then IDByTypeTaken[uname][self.IDByType] = nil end
		if ai.totalCons[uname] ~= nil then ai.totalCons[uname] = ai.totalCons[uname] - 1 end
		self.IDByType = nil
		ai.assisthandler:RemoveWorking(self)
		ai.assisthandler:RemoveFree(self)
	end
end

function AssistBehaviour:Assign(builder)
	self.target = builder
end

function AssistBehaviour:AssignIDByType()
	local uname = self.name
	if IDByTypeTaken[uname] == nil then
		self.IDByType = 1
		IDByTypeTaken[uname] = {}
		IDByTypeTaken[uname][1] = true
	else
		if self.IDByType ~= nil then
			IDByTypeTaken[uname][self.IDByType] = nil
		end
		local id = 1
		while id <= ai.totalCons[uname] do
			id = id + 1
			if not IDByTypeTaken[uname][id] then break end
		end
		self.IDByType = id
		IDByTypeTaken[uname][id] = true
	end
	if self.active then
		if self:DoIAssist() then
			ai.assisthandler:AddFree(self)
		end
	end
end