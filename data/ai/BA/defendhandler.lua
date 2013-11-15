require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("DefendHandler: " .. inStr)
	end
end

local factoryPriority = 3
local damagedPriority = 4
local techLevelPriority = 1
local commanderPriority = 2

DefendHandler = class(Module)

function DefendHandler:Name()
	return "DefendHandler"
end

function DefendHandler:internalName()
	return "defendhandler"
end

function DefendHandler:Init()
	 self.defenders = {}
	 self.defendees = {}
	 self.totalPriority = 0
end

function DefendHandler:UnitCreated(unit)
	-- local unit = u:Internal()
	local un = unit:Name()
	local utable = unitTable[un]
	local priority = 0
	if utable.buildOptions then
		priority = priority + utable.techLevel * techLevelPriority
		if utable.isBuilding then
			priority = priority + factoryPriority
		elseif un == "corcom" or un == "armcom" then
			priority = priority + commanderPriority
		end
	end
	if priority ~= 0 then
		table.insert(self.defendees, {unit = unit, uid = unit:ID(), priority = priority, damaged = nil})
		self.totalPriority = self.totalPriority + priority
		self:AssignAll()
	end
end

function DefendHandler:UnitDamaged(unit)

end

function DefendHandler:UnitDead(unit)
	-- local unit = u:Internal()
	local uid = unit:ID()
	for i, defendee in pairs(self.defendees) do
		if uid == defendee.uid then
			-- game:SendToConsole("defendee " .. defendee.unit:Name() .. " died")
			EchoDebug("defendee with id " .. uid .. " dead. there are " .. #self.defendees .. " defendees total")
			for di, dfndbehaviour in pairs(self.defenders) do
				if dfndbehaviour.target ~= nil then
					if dfndbehaviour.target:ID() == uid then
						dfndbehaviour:Assign(nil)
					end
				end
			end
			self.totalPriority = self.totalPriority - defendee.priority
			defendee.unit = nil
			defendee = nil
			table.remove(self.defendees, i)
			EchoDebug("defendee removed from table. there are " .. #self.defendees .. " defendees total")
			self:AssignAll()
			break
		end
	end
end

function DefendHandler:Update()
	local f = game:Frame()
	if f % 30 == 0 then
		local damage = false
		for i, defendee in pairs(self.defendees) do
			if defendee.damaged ~= nil then
				damage = true
				-- defend damaged for thirty seconds after they've stopped being fired at
				if f > defendee.damaged + 900 then
					defendee.priority = defendee.priority - damagedPriority
					self.totalPriority = self.totalPriority - damagedPriority
					defendee.damaged = nil
					if defendee.priority == 0 then
						table.remove(self.defendees, i)
					end
				end
			end
		end
		if damage then self:AssignAll() end
	end
end

function DefendHandler:AssignAll()
	if #self.defenders == 0 then return end
	EchoDebug("assigning all defenders...")
	if #self.defendees == 0 then 
		-- if nothing to defend, make sure defenders aren't defending ghosts (this causes a crash)
		for di, dfndbehaviour in pairs(self.defenders) do
			dfndbehaviour:Assign(nil)
		end
	end
	-- assign defenders to defendees
	local defendersPerPriority = #self.defenders / self.totalPriority
	local defendersToAssign = {}
	local defendersToRemove = {}
	for nothing, dfndbehaviour in pairs(self.defenders) do
		table.insert(defendersToAssign, dfndbehaviour)
	end
	local notDefended = {}
	for i, defendee in pairs(self.defendees) do
		local number = math.floor(defendee.priority * defendersPerPriority)
		if number ~= 0 and #defendersToAssign ~= 0 then
			local defendeePos = defendee.unit:GetPosition()
			-- put into table to sort by distance
			local bydistance = {}
			for di, dfndbehaviour in pairs(defendersToAssign) do
				local okay = true
				for nothing, removedfndbehaviour in pairs(defendersToRemove) do
					if removedfndbehaviour == dfndbehaviour then
						table.remove(defendersToAssign, di)
						okay = false
						break
					end
				end
				if okay then
					local defender = dfndbehaviour.unit:Internal()
					if ai.maphandler:UnitCanGetToUnit(defender, defendee.unit) then
						local defenderPos = defender:GetPosition()
						local dist = quickdistance(defenderPos, defendeePos)
						bydistance[dist] = dfndbehaviour -- the probability of the same distance is near zero
					end
				end
			end
			-- add as many as needed, closest first
			local n = 0
			for dist, dfndbehaviour in pairsByKeys(bydistance) do
				if n < number then
					dfndbehaviour:Assign(defendee.unit)
					table.insert(defendersToRemove, dfndbehaviour)
				else
					break
				end
				n = n + 1
			end
		elseif number == 0 then
			notDefended[i] = true
		end
	end
	if #defendersToAssign ~= 0 then
		for i, tf in pairs(notDefended) do
			local defendee = self.defendees[i]
			if #defendersToAssign ~= 0 then
				local dfndbehaviour = table.remove(defendersToAssign)
				dfndbehaviour:Assign(defendee.unit)
			else
				break
			end
		end
	end
	EchoDebug("all defenders assigned")
end

function DefendHandler:IsDefendingMe(defenderUnit, defendeeUnit)
	local defenderID = defenderUnit:ID()
	local defendeeID = defendeeUnit:ID()
	for i, dfndbehaviour in pairs(self.defenders) do
		if dfndbehaviour.unit:Internal() ~= nil then
			if dfndbehaviour.unit:Internal():ID() == defenderID then
				if dfndbehaviour.target ~= nil then
					if dfndbehaviour.target:ID() == defendeeID then
						return true
					end
				end
			end
		end
	end
	return false
end

function DefendHandler:IsDefender(dfndbehaviour)
	for i, db in pairs(self.defenders) do
		if db == dfndbehaviour then
			return true
		end
	end
	return false
end

function DefendHandler:AddDefender(dfndbehaviour)
	if not self:IsDefender(dfndbehaviour) then
		table.insert(self.defenders, dfndbehaviour)
		self:AssignAll()
	end
end

function DefendHandler:RemoveDefender(dfndbehaviour)
	for i, db in pairs(self.defenders) do
		if db == dfndbehaviour then
			table.remove(self.defenders, i)
			self:AssignAll()
			break
		end
	end
end

-- receive a signal that a unit is threatened
function DefendHandler:Danger(defendeeUnit)
	local defendeeID = defendeeUnit:ID()
	for i, defendee in pairs(self.defendees) do
		if defendee.uid == defendeeID then
			if not defendee.damaged then
				EchoDebug("defendee damaged")
				defendee.damaged = game:Frame()
				defendee.priority = defendee.priority + damagedPriority
				self.totalPriority = self.totalPriority + damagedPriority
			end
			return
		end
	end
	-- if it's not a defendee, make it one
	local defendee = {unit = defendeeUnit, uid = defendeeUnit:ID(), priority = damagedPriority, damaged = game:Frame()}
	table.insert(self.defendees, defendee)
	self.totalPriority = self.totalPriority + damagedPriority
end