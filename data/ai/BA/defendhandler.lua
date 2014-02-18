require "common"


local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("DefendHandler: " .. inStr)
	end
end

-- local factoryPriority = 3
local threatenedPriority = 4
local turtleThreatenedPriority = 20
local techLevelPriority = 1
local commanderPriority = 1.5

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
	 self.hangers = {}
	 self.totalPriority = 0
	 self.lastAssignFrame = 0
end

function DefendHandler:AddDefendee(behaviour, turtle)
	local priority = 0
	local defendee
	if behaviour ~= nil then
		if behaviour.unit == nil then return end
		if behaviour.name == nil then behaviour.name = behaviour.unit:Internal():Name() end
		if behaviour.id == nil then behaviour.id = behaviour.unit:Internal():ID() end
		local un = behaviour.name
		local utable = unitTable[un]
		priority = utable.techLevel * techLevelPriority
		if commanderList[un] then priority = priority + commanderPriority end
		defendee = { uid = behaviour.id, behaviour = behaviour, priority = priority, threatened = nil, defenders = {}, guardDistance = self:GetGuardDistance(un) }
	elseif turtle ~= nil then
		priority = 0
		defendee = { turtle = turtle, position = turtle.position, priority = priority, threatened = f, defenders = {}, guardDistance = turtle.size, scrambleForMe = turtle.priority > 4 }
	end
	if defendee ~= nil then
		table.insert(self.defendees, defendee)
		self.totalPriority = self.totalPriority + priority
		self.needAssignment = true
	end
end

function DefendHandler:RemoveDefendee(behaviour, turtle)
	for i, defendee in pairs(self.defendees) do
		-- either behaviour or turtle should be nil
		if behaviour == defendee.behaviour and turtle == defendee.turtle then
			for di, dfndbehaviour in pairs(self.defenders) do
				if dfndbehaviour.target ~= nil then
					if dfndbehaviour.target == uid then
						dfndbehaviour:Assign(nil)
					end
				end
			end
			self.totalPriority = self.totalPriority - defendee.priority
			table.remove(self.defendees, i)
			EchoDebug("defendee removed from table. there are " .. #self.defendees .. " defendees total")
			self.needAssignment = true
			break
		end
	end
end

function DefendHandler:Update()
	local f = game:Frame()
	if f % 30 == 0 then
		local scrambleCalls = 0
		for i, defendee in pairs(self.defendees) do
			if defendee.behaviour ~= nil then
				if not defendee.behaviour.isScout then
					if defendee.threatened then
						if not defendee.behaviour.underFire then
							defendee.priority = defendee.priority - threatenedPriority
							self.totalPriority = self.totalPriority - threatenedPriority
							defendee.threatened = nil
							self.needAssignment = true
						end
					else
						if defendee.behaviour.withinTurtle then
							defendee.prioritySnap = defendee.priority+0
							self.totalPriority = self.totalPriority - defendee.priority
							defendee.priority = 0
							self.needAssignment = true
						else
							if defendee.prioritySnap ~= nil then
								defendee.priority = defendee.prioritySnap
								self.totalPriority = self.totalPriority + defendee.priority
								defendee.prioritySnap = nil
								self.needAssignment = true
							end
							if defendee.behaviour.underFire then
								defendee.priority = defendee.priority + threatenedPriority
								self.totalPriority = self.totalPriority + threatenedPriority
								defendee.threatened = f
								self.needAssignment = true
							end
						end
					end
				end
			elseif defendee.turtle ~= nil then
				if defendee.threatened ~= nil then
					-- defend threatened for thirty seconds after they've stopped being threatened
					if f > defendee.threatened + 450 then
						self.totalPriority = self.totalPriority - defendee.priority
						defendee.priority = 0
						self.needAssignment = true
					else
						if defendee.scrambleForMe then scrambleCalls = scrambleCalls + 1 end
					end
				end
			end
		end
		if scrambleCalls ~= 0 then
			self:Scramble()
		else
			self:Unscramble()
		end
	end
	if self.needAssignment and f > self.lastAssignFrame + 30 then
		-- only actually reassign every second
		self:AssignAll()
		self.lastAssignFrame = f
		self.needAssignment = nil
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
		defendee.defenders = {}
		local number = math.floor(defendee.priority * defendersPerPriority)
		if number ~= 0 and #defendersToAssign ~= 0 then
			local defendeePos = defendee.position
			if defendeePos == nil and defendee.behaviour ~= nil then 
				if defendee.behaviour ~= nil then
					if defendee.behaviour.unit ~= nil then
						defendeeUnit = defendee.behaviour.unit:Internal()
						if defendeeUnit ~= nil then
							defendeePos = defendeeUnit:GetPosition()
						end
					end
				end
			end
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
					if dfndbehaviour == nil then
						okay = false
					elseif dfndbehaviour.unit == nil then
						okay = false
					end
				end
				if okay then
					local defender = dfndbehaviour.unit:Internal()
					if ai.maphandler:UnitCanGoHere(defender, defendeePos) then
						local defenderPos = defender:GetPosition()
						local dist = Distance(defenderPos, defendeePos)
						bydistance[dist] = dfndbehaviour -- the probability of the same distance is near zero
					end
				end
			end
			-- add as many as needed, closest first
			local n = 0
			for dist, dfndbehaviour in pairsByKeys(bydistance) do
				if n < number then
					-- dfndbehaviour:Assign(defendee)
					table.insert(defendee.defenders, dfndbehaviour)
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
				table.insert(defendee.defenders, dfndbehaviour)
			else
				break
			end
		end
	end
	-- assign siege units to hang around near the front
	if self.frontDefendee ~= nil and self.frontDefendee.turtle.ground + self.frontDefendee.turtle.air + self.frontDefendee.turtle.submerged > 0 then
		local defendee= self.frontDefendee
		local d = -defendee.guardDistance * 0.5
		local dAdd = defendee.guardDistance / #self.hangers
		for i = 1, #self.hangers do
			local dfndbehaviour = self.hangers[i]
			dfndbehaviour:Assign(defendee, defendee.angle, d)
			d = d + dAdd
		end
	end
	-- find angles for each defender
	for i, defendee in pairs(self.defendees) do
		local divisor = #defendee.defenders
		-- if defendee.turtle ~= nil and divisor > 0 then game:SendToConsole("turtle with " .. divisor .. " of " .. #self.defenders) end
		if divisor > 0 then
			if defendee.angle == nil then
				local angleAdd = twicePi / divisor
				local angle = math.random() * twicePi
				for nothing, dfndbehaviour in pairs(defendee.defenders) do
					dfndbehaviour:Assign(defendee, angle)
					angle = angle + angleAdd
					if angle > twicePi then angle = angle - twicePi end
				end
			else
				local angle = defendee.angle
				local d = -defendee.guardDistance
				local dAdd = (defendee.guardDistance * 2) / divisor
				for nothing, dfndbehaviour in pairs(defendee.defenders) do
					dfndbehaviour:Assign(defendee, angle, d)
					d = d + dAdd
				end
			end
		end
	end
	EchoDebug("all defenders assigned")
end

function DefendHandler:IsDefendingMe(defenderUnit, defendeeUnit)
	local defenderID = defenderUnit:ID()
	local defendeeID = defendeeUnit:ID()
	for i, dfndbehaviour in pairs(self.defenders) do
		if dfndbehaviour.unit ~= nil then
			if dfndbehaviour.unit:Internal():ID() == defenderID then
				if dfndbehaviour.target ~= nil then
					if dfndbehaviour.target == defendeeID then
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

function DefendHandler:IsFrontOnly(dfndbehaviour)
	for i, db in pairs(self.hangers) do
		if db == dfndbehaviour then
			return true
		end
	end
	return false
end

function DefendHandler:AddDefender(dfndbehaviour)
	if dfndbehaviour.tough or dfndbehaviour.aa then
		if not self:IsDefender(dfndbehaviour) then
			table.insert(self.defenders, dfndbehaviour)
			self.needAssignment = true
		end
	else
		if not self:IsFrontOnly(dfndbehaviour) then
			table.insert(self.hangers, dfndbehaviour)
			self.needAssignment = true
		end
	end
end

function DefendHandler:RemoveDefender(dfndbehaviour)
	if dfndbehaviour.tough or dfndbehaviour.aa then
		for i, db in pairs(self.defenders) do
			if db == dfndbehaviour then
				table.remove(self.defenders, i)
				self.needAssignment = true
				return
			end
		end
	else
		for i, db in pairs(self.hangers) do
			if db == dfndbehaviour then
				table.remove(self.hangers, i)
				self.needAssignment = true
				return
			end
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

-- receive a signal that a building is threatened or a turtle is on the front
function DefendHandler:Danger(behaviour, turtle)
	local f = game:Frame()
	if turtle == nil and behaviour ~= nil then turtle = ai.turtlehandler:GetUnitTurtle(behaviour.id) end
	if turtle ~= nil then
		for i, defendee in pairs(self.defendees) do
			if defendee.turtle == turtle then
				defendee.threatened = f
				if defendee.priority == 0 then
					if turtle.front then
						turtleThreatenedPriority = self.totalPriority+0
						local priority = turtleThreatenedPriority
						defendee.priority = priority
						defendee.angle = turtle.threatForecastAngle
						defendee.scrambleForMe = turtle.priority > 4
						self.totalPriority = self.totalPriority + priority
						self.frontDefendee = defendee
						self.needAssignment = true
					else
						local priority = turtle.priority
						defendee.priority = priority
						defendee.scrambleForMe = turtle.priority > 4
						self.totalPriority = self.totalPriority + priority
						self.needAssignment = true
					end
				end
				return
			end
		end
	end
end

function DefendHandler:DefendeeSafe(defendee)
	local f = game:Frame()
	local behaviour = defendee.behaviour
	local threatened = defendee.threatened
	if behaviour ~= nil then
		return not behaviour.underFire
	elseif threatened ~= nil then
		return f > threatened + 300
	end
	return true
end

function DefendHandler:GetGuardDistance(unitName)
	local utable = unitTable[unitName]
	return (math.max(utable.xsize, utable.zsize) * 4) + 100
end