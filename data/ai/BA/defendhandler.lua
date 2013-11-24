require "unitlists"
require "unittable"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("DefendHandler: " .. inStr)
	end
end

-- local factoryPriority = 3
local threatenedPriority = 4
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
	 self.scrambles = {}
	 self.totalPriority = 0
	 self.lastThreats = 0
end

function DefendHandler:UnitCreated(unit)
	-- local unit = u:Internal()
	local un = unit:Name()
	local utable = unitTable[un]
	local priority = 0
	if utable.buildOptions and not utable.isBuilding then
		priority = priority + utable.techLevel * techLevelPriority
		-- if utable.isBuilding then
		-- 	priority = priority + factoryPriority
		if un == "corcom" or un == "armcom" then
			priority = priority + commanderPriority
		end
	end
	if priority ~= 0 then
		table.insert(self.defendees, {unit = unit, uid = unit:ID(), priority = priority, threatened = nil})
		self.totalPriority = self.totalPriority + priority
		self:AssignAll()
	end
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
		local threats = 0
		local scrambleCalls = 0
		for i, defendee in pairs(self.defendees) do
			if defendee.threatened ~= nil then
				threats = threats + 1
				if defendee.scrambleForMe then scrambleCalls = scrambleCalls + 1 end
				-- defend threatened for thirty seconds after they've stopped being within range of fire or fired at
				if f > defendee.threatened + 900 then
					defendee.priority = defendee.priority - threatenedPriority
					self.totalPriority = self.totalPriority - threatenedPriority
					defendee.threatened = nil
					if defendee.priority == 0 then
						table.remove(self.defendees, i)
					end
				end
			end
		end
		if scrambleCalls ~= 0 then
			self:Scramble()
		else
			self:Unscramble()
		end
		if threats ~= self.lastThreats then
			self:AssignAll()
		end
		self.lastThreats = threats
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
			local defendeePos = defendee.position
			if defendeePos == nil then defendeePos = defendee.unit:GetPosition() end
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
					if ai.maphandler:UnitCanGoHere(defender, defendeePos) then
						local defenderPos = defender:GetPosition()
						local dist = distance(defenderPos, defendeePos)
						bydistance[dist] = dfndbehaviour -- the probability of the same distance is near zero
					end
				end
			end
			-- add as many as needed, closest first
			local n = 0
			for dist, dfndbehaviour in pairsByKeys(bydistance) do
				if n < number then
					dfndbehaviour:Assign(defendee)
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
				dfndbehaviour:Assign(defendee)
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

function DefendHandler:IsScramble(dfndbehaviour)
	for i, db in pairs(self.scrambles) do
		if db == dfndbehaviour then
			return true
		end
	end
	return false
end

function DefendHandler:AddScramble(dfndbehaviour)
	if not self:IsScramble(dfndbehaviour) then
		table.insert(self.scrambles, dfndbehaviour)
		if self.scrambling then
			dfndbehaviour.scrambled = true
		end
	end
end

function DefendHandler:RemoveScramble(dfndbehaviour)
	for i, db in pairs(self.scrambles) do
		if db == dfndbehaviour then
			table.remove(self.scrambles, i)
			break
		end
	end
end

function DefendHandler:Scramble()
	if not self.scrambling then
		for i, db in pairs(self.scrambles) do
			db:Scramble()
		end
		self.scrambling = true
	end
end

function DefendHandler:Unscramble()
	if self.scrambling then
		for i, db in pairs(self.scrambles) do
			db:Unscramble()
		end
		self.scrambling = false
	end
end

-- receive a signal that a unit is threatened
function DefendHandler:Danger(defendeeUnit)
	local defendeeID = defendeeUnit:ID()
	for i, defendee in pairs(self.defendees) do
		if defendee.uid == defendeeID then
			if not defendee.threatened then
				EchoDebug("defendee threatened")
				defendee.threatened = game:Frame()
				defendee.priority = defendee.priority + threatenedPriority
				self.totalPriority = self.totalPriority + threatenedPriority
			end
			return
		end
	end
	-- if it's not a defendee, make it one
	local defendee = {priority = threatenedPriority, threatened = game:Frame()}
	local uname = defendeeUnit:Name()
	local turtlePriority = 0
	if turtleList[uname] then turtlePriority = turtleList[uname] end
	if unitTable[uname].buildOptions or turtlePriority > 2 then defendee.scrambleForMe = true end
	if unitTable[uname].isBuilding then
		defendee.position = defendeeUnit:GetPosition()
	else
		defendee.unit = defendeeUnit
		defendee.uid = defendeeUnit:ID()
	end
	table.insert(self.defendees, defendee)
	self.totalPriority = self.totalPriority + threatenedPriority
end