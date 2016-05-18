shard_include "common"


local DebugEnabled = false


local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("TaskQueueBehaviour: " .. inStr)
	end
end

local CMD_GUARD = 25

local extraEnergy, extraMetal, energyTooLow, energyOkay, metalTooLow, metalOkay, metalBelowHalf, metalAboveHalf, notEnoughCombats, farTooFewCombats

local function GetEcon()
	extraEnergy = ai.Energy.income - ai.Energy.usage
	extraMetal = ai.Metal.income - ai.Metal.usage
	local enoughMetalReserves = math.min(ai.Metal.income, ai.Metal.capacity * 0.1)
	local lotsMetalReserves = math.min(ai.Metal.income * 10, ai.Metal.capacity * 0.5)
	local enoughEnergyReserves = math.min(ai.Energy.income * 2, ai.Energy.capacity * 0.25)
	-- local lotsEnergyReserves = math.min(ai.Energy.income * 3, ai.Energy.capacity * 0.5)
	energyTooLow = ai.Energy.reserves < enoughEnergyReserves or ai.Energy.income < 40
	energyOkay = ai.Energy.reserves >= enoughEnergyReserves and ai.Energy.income >= 40
	metalTooLow = ai.Metal.reserves < enoughMetalReserves
	metalOkay = ai.Metal.reserves >= enoughMetalReserves
	metalBelowHalf = ai.Metal.reserves < lotsMetalReserves
	metalAboveHalf = ai.Metal.reserves >= lotsMetalReserves
	local attackCounter = ai.attackhandler:GetCounter()
	notEnoughCombats = ai.combatCount < attackCounter * 0.6
	farTooFewCombats = ai.combatCount < attackCounter * 0.2
end

TaskQueueBehaviour = class(Behaviour)

function TaskQueueBehaviour:CategoryEconFilter(value)
	if value == nil then return DummyUnitName end
	if value == DummyUnitName then return DummyUnitName end
	EchoDebug(value .. " (before econ filter)")
	-- EchoDebug("ai.Energy: " .. ai.Energy.reserves .. " " .. ai.Energy.capacity .. " " .. ai.Energy.income .. " " .. ai.Energy.usage)
	-- EchoDebug("ai.Metal: " .. ai.Metal.reserves .. " " .. ai.Metal.capacity .. " " .. ai.Metal.income .. " " .. ai.Metal.usage)
	if Eco1[value] or Eco2[value] then
		return value
	end
	if nanoTurretList[value] then
		-- nano turret
		EchoDebug(" nano turret")
		if metalBelowHalf or energyTooLow or farTooFewCombats then
			value = DummyUnitName
		end
	elseif reclaimerList[value] then
		-- dedicated reclaimer
		EchoDebug(" dedicated reclaimer")
		if metalAboveHalf or energyTooLow or farTooFewCombats then
			value = DummyUnitName
		end
	elseif unitTable[value].isBuilding then
		-- buildings
		EchoDebug(" building")
		if unitTable[value].extractsMetal > 0 then
			-- metal extractor
			EchoDebug("  mex")
			if energyTooLow and ai.Metal.income > 3 then
				value = DummyUnitName
			end
		elseif value == "corwin" or value == "armwin" or value == "cortide" or value == "armtide" or (unitTable[value].totalEnergyOut > 0 and not unitTable[value].buildOptions) then
			-- energy plant
			EchoDebug("  energy plant")
			if bigEnergyList[uname] then
				-- big energy plant
				EchoDebug("   big energy plant")
				-- don't build big energy plants until we have the resources to do so
				if energyOkay or metalTooLow or ai.Energy.income < 400 or ai.Metal.income < 35 then
					value = DummyUnitName
				end
				if self.name == "coracv" and value == "corfus" and ai.Energy.income > 4000 then
					-- build advanced fusion
					value = "cafus"
				elseif self.name == "armacv" and value == "armfus" and ai.Energy.income > 4000 then
					-- build advanced fusion
					value = "aafus"
				end
				-- don't build big energy plants less than fifteen seconds from one another
				if ai.lastNameFinished[value] ~= nil then
					if game:Frame() < ai.lastNameFinished[value] + 450 then
						value = DummyUnitName
					end
				end
			else
				if energyOkay or metalTooLow then
					value = DummyUnitName
				end
			end
		elseif unitTable[value].buildOptions ~= nil then
			-- factory
			EchoDebug("  factory")
			EchoDebug(ai.factories)
			if ai.factories - ai.outmodedFactories <= 0 and metalOkay and energyOkay and ai.Metal.income > 3 and ai.Metal.reserves > unitTable[value].metalCost * 0.7 then
				EchoDebug("   first factory")
				-- build the first factory
			elseif advFactories[value] and metalOkay and energyOkay then
				-- build advanced factory
			elseif expFactories[value] and metalOkay and energyOkay then
				-- build experimental factory
			else
				if ai.couldAttack >= 1 or ai.couldBomb >= 1 then
					-- other factory after attack
					if metalTooLow or ai.Metal.income < (ai.factories - ai.outmodedFactories) * 8 or energyTooLow or (ai.needAdvanced and not ai.haveAdvFactory) then
						value = DummyUnitName
					end
				else
					-- other factory before attack more stringent
					if metalBelowHalf or ai.Metal.income < (ai.factories - ai.outmodedFactories) * 12 or energyTooLow or (ai.needAdvanced and not ai.haveAdvFactory) then
						value = DummyUnitName
					end
				end
			end
		elseif unitTable[value].isWeapon then
			-- defense
			EchoDebug("  defense")
			if bigPlasmaList[value] or nukeList[value] then
				-- long-range plasma and nukes aren't really defense
				if metalTooLow or energyTooLow or ai.Metal.income < 35 or ai.factories == 0 or notEnoughCombats then
					value = DummyUnitName
				end
			elseif littlePlasmaList[value] then
				-- plasma turrets need units to back them up
				if metalTooLow or energyTooLow or ai.Metal.income < 10 or ai.factories == 0 or notEnoughCombats then
					value = DummyUnitName
				end
			else
				if metalTooLow or ai.Metal.income < (unitTable[value].metalCost / 35) + 2 or energyTooLow or ai.factories == 0 then
					value = DummyUnitName
				end
			end
		elseif unitTable[value].radarRadius > 0 then
			-- radar
			EchoDebug("  radar")
			if metalTooLow or energyTooLow or ai.factories == 0 then
				value = DummyUnitName
			end
		else
			-- other building
			EchoDebug("  other building")
			if notEnoughCombats or metalTooLow or energyTooLow or ai.Energy.income < 200 or ai.Metal.income < 8 or ai.factories == 0 then
				value = DummyUnitName
			end
		end
	else
		-- moving units
		EchoDebug(" moving unit")
		if unitTable[value].buildOptions ~= nil then
			-- construction unit
			EchoDebug("  construction unit")
			if advConList[value] then
				-- advanced construction unit
				if (ai.nameCount[value] == nil or ai.nameCount[value] == 0) then
					-- build at least one of each advanced con (a mex upgrader)
					if metalTooLow or energyTooLow or (farTooFewCombats and not self.outmodedFactory) then
						value = DummyUnitName
					end
				elseif ai.nameCount[value] == 1 then
					-- build another fairly easily
					if metalTooLow or energyTooLow or ai.Metal.income < 18 or (farTooFewCombats and not self.outmodedFactory) then
						value = DummyUnitName
					end
				else
					if metalBelowHalf or energyTooLow or ai.nameCount[value] > ai.conCount + ai.assistCount / 3 or notEnoughCombats then
						value = DummyUnitName
					end
				end
			elseif (ai.nameCount[value] == nil or ai.nameCount[value] == 0) and metalOkay and energyOkay and (self.outmodedFactory or not farTooFewCombats) then
				-- build at least one of each type
			elseif assistList[value] then
				-- build enough assistants
				if metalBelowHalf or energyTooLow or ai.assistCount > ai.Metal.income * 0.125 then
					value = DummyUnitName
				end
			elseif value == "corcv" and ai.nameCount["coracv"] ~= 0 and ai.nameCount["coracv"] ~= nil and (ai.nameCount["coralab"] == 0 or ai.nameCount["coralab"] == nil) then
				-- core doesn't have consuls, so treat lvl1 con vehicles like assistants, if there are no other alternatives
				if metalBelowHalf or energyTooLow or ai.conCount > ai.Metal.income * 0.15 then
					value = DummyUnitName
				end
			else
				EchoDebug(ai.combatCount .. " " .. ai.conCount .. " " .. tostring(metalBelowHalf) .. " " .. tostring(energyTooLow))
				if metalBelowHalf or energyTooLow or (ai.combatCount < ai.conCount * 4 and not self.outmodedFactory and not self.isAirFactory and not self.isShipyard) then
					value = DummyUnitName
				end
			end
		elseif unitTable[value].isWeapon then
			-- combat unit
			EchoDebug("  combat unit")
			if metalTooLow or energyTooLow then
				value = DummyUnitName
			end
		elseif value == "armpeep" or value == "corfink" then
			-- scout planes have no weapons
			if metalTooLow or energyTooLow then
				value = DummyUnitName
			end
		else
			-- other unit
			EchoDebug("  other unit")
			if notEnoughCombats or metalBelowHalf or energyTooLow then
				value = DummyUnitName
			end
		end
	end
	return value
end

function TaskQueueBehaviour:Init()
	shard_include "taskqueues"
	if ai.outmodedFactories == nil then ai.outmodedFactories = 0 end

	GetEcon()
	self.active = false
	self.currentProject = nil
	self.lastWatchdogCheck = game:Frame()
	self.watchdogTimeout = 1800
	local u = self.unit:Internal()
	local mtype, network = ai.maphandler:MobilityOfUnit(u)
	self.mtype = mtype
	self.name = u:Name()
	if commanderList[self.name] then self.isCommander = true end
	self.id = u:ID()

	-- register if factory is going to use outmoded queue
	if factoryMobilities[self.name] ~= nil then
		self.isFactory = true
		local upos = u:GetPosition()
		self.position = upos
		local outmoded = true
		for i, mtype in pairs(factoryMobilities[self.name]) do
			if not ai.maphandler:OutmodedFactoryHere(mtype, upos) then
				-- just one non-outmoded mtype will cause the factory to act normally
				outmoded = false
			end
			if mtype == "air" then self.isAirFactory = true end
		end
		if outmoded then
			EchoDebug("outmoded " .. self.name)
			self.outmodedFactory = true
			ai.outmodedFactoryID[self.id] = true
			ai.outmodedFactories = ai.outmodedFactories + 1
			ai.outmodedFactories = 1
		end
	end

	-- reset attack count
	if self.isFactory and not self.outmodedFactory then
		if self.isAirFactory then
			ai.couldBomb = 0
			ai.hasBombed = 0
		else
			ai.couldAttack = 0
			ai.hasAttacked = 0
		end
	end

	if self:HasQueues() then
		self.queue = self:GetQueue()
	end
	
end

function TaskQueueBehaviour:HasQueues()
	return (taskqueues[self.name] ~= nil)
end

function TaskQueueBehaviour:UnitCreated(unit)
	if unit.engineID == self.unit.engineID then

	end
end

function TaskQueueBehaviour:UnitBuilt(unit)
	if self.unit == nil then return end
	if unit.engineID == self.unit.engineID then
		if self:IsActive() then self.progress = true end
	end
end

function TaskQueueBehaviour:UnitIdle(unit)
	if not self:IsActive() then
		return
	end
	if self.unit == nil then return end
	if unit.engineID == self.unit.engineID then
		self.progress = true
		self.currentProject = nil
		ai.buildsitehandler:ClearMyPlans(self)
		self.unit:ElectBehaviour()
	end
end

function TaskQueueBehaviour:UnitMoveFailed(unit)
	-- sometimes builders get stuck
	self:UnitIdle(unit)
end

function TaskQueueBehaviour:UnitDead(unit)
	if self.unit ~= nil then
		if unit.engineID == self.unit.engineID then
			-- game:SendToConsole("taskqueue-er " .. self.name .. " died")
			if self.outmodedFactory then ai.outmodedFactories = ai.outmodedFactories - 1 end
			-- self.unit = nil
			if self.target then ai.targethandler:AddBadPosition(self.target, self.mtype) end
			ai.assisthandler:Release(nil, self.id, true)
			ai.buildsitehandler:ClearMyPlans(self)
			ai.buildsitehandler:ClearMyConstruction(self)
		end
	end
end

function TaskQueueBehaviour:GetHelp(value, position)
	if value == nil then return DummyUnitName end
	if value == DummyUnitName then return DummyUnitName end
	EchoDebug(value .. " before getting help")
	local builder = self.unit:Internal()
	if Eco1[value] then
		return value
	end
	if Eco2[value] then
		local hashelp = ai.assisthandler:PersistantSummon(builder, position, math.ceil(unitTable[value].buildTime/10000), 0)
		return value
	end
	if helpList[value] then
		local hashelp = ai.assisthandler:PersistantSummon(builder, position, helpList[value], 1)
		if hashelp then
			return value
		end
	elseif unitTable[value].isBuilding and unitTable[value].buildOptions then
		if ai.factories - ai.outmodedFactories <= 0 or advFactories[value] then
			EchoDebug("can get help to build factory but don't need it")
			ai.assisthandler:Summon(builder, position)
			ai.assisthandler:Magnetize(builder, position)
			return value
		else
			local hashelp = ai.assisthandler:Summon(builder, position, ai.factories)
			if hashelp then
				ai.assisthandler:Magnetize(builder, position)
				return value
			end
		end
	else
		local number
		if self.isFactory then
			-- factories have more nano output
			number = math.floor((unitTable[value].metalCost + 1000) / 1500)
		else
			number = math.floor((unitTable[value].metalCost + 750) / 1000)
		end
		if number == 0 then return value end
		local hashelp = ai.assisthandler:Summon(builder, position, number)
		if hashelp or self.isFactory then return value end
	end
	return DummyUnitName
end

function TaskQueueBehaviour:LocationFilter(utype, value)
	if self.isFactory then return utype, value end -- factories don't need to look for build locations
	local p
	local builder = self.unit:Internal()
	if unitTable[value].extractsMetal > 0 then
		-- metal extractor
		local uw
		p, uw, reclaimEnemyMex = ai.maphandler:ClosestFreeSpot(utype, builder)
		if p ~= nil then
			if reclaimEnemyMex then
				value = {"ReclaimEnemyMex", reclaimEnemyMex}
			else
				EchoDebug("extractor spot: " .. p.x .. ", " .. p.z)
				if uw then
					EchoDebug("underwater extractor " .. uw:Name())
					utype = uw
					value = uw:Name()
				end
			end
		else
			utype = nil
		end
	elseif geothermalPlant[value] then
		-- geothermal
		p = self.ai.maphandler:ClosestFreeGeo(utype, builder)
		-- Spring.Echo("geo spot", p.x, p.y, p.z)
		if p then
			if value == "cmgeo" or value == "amgeo" then
				-- don't build moho geos next to factories
				if ai.buildsitehandler:ClosestHighestLevelFactory(builder, 500) ~= nil then
					if value == "cmgeo" then
						if ai.targethandler:IsBombardPosition(p, "corbhmth") then
							-- instead build geothermal plasma battery if it's a good spot for it
							value = "corbhmth"
							utype = game:GetTypeByName(value)
						end
					else
						-- instead build a safe geothermal
						value = "armgmm"
						utype = game:GetTypeByName(value)
					end
				end
			end
		else
			utype = nil
		end
	elseif nanoTurretList[value] then
		-- build nano turrets next to a factory near you
		EchoDebug("looking for factory for nano")
		local factoryPos = ai.buildsitehandler:ClosestHighestLevelFactory(builder, 5000)
		if factoryPos then
			EchoDebug("found factory")
			p = ai.buildsitehandler:ClosestBuildSpot(builder, factoryPos, utype)
			if p == nil then
				EchoDebug("no spot near factory found")
				utype = nil
			end
		else
			EchoDebug("no factory found")
			utype = nil
		end
	elseif nukeList[value] or bigPlasmaList[value] or littlePlasmaList[value] then
		-- bombarders
		EchoDebug("seeking bombard build spot")
		local turtlePosList = ai.turtlehandler:MostTurtled(builder, value, value)
		if turtlePosList then
			EchoDebug("got sorted turtle list")
			if #turtlePosList ~= 0 then
				EchoDebug("turtle list has turtles")
				for i, turtlePos in ipairs(turtlePosList) do
					p = ai.buildsitehandler:ClosestBuildSpot(builder, turtlePos, utype)
					if p ~= nil then break end
				end
			end
		end
		if p == nil then
			utype = nil
			EchoDebug("could not find bombard build spot")
		else
			EchoDebug("found bombard build spot")
		end
	elseif shieldList[value] or antinukeList[value] or unitTable[value].jammerRadius ~= 0 or unitTable[value].radarRadius ~= 0 or unitTable[value].sonarRadius ~= 0 or (unitTable[value].isWeapon and unitTable[value].isBuilding and not nukeList[value] and not bigPlasmaList[value] and not littlePlasmaList[value]) then
		-- shields, defense, antinukes, jammer towers, radar, and sonar
		EchoDebug("looking for least turtled positions")
		local turtlePosList = ai.turtlehandler:LeastTurtled(builder, value)
		if turtlePosList then
			if #turtlePosList ~= 0 then
				EchoDebug("found turtle positions")
				for i, turtlePos in ipairs(turtlePosList) do
					p = ai.buildsitehandler:ClosestBuildSpot(builder, turtlePos, utype)
					if p ~= nil then break end
				end
			end
		end
		if p and Distance(p, builder:GetPosition()) > 300 then
			-- HERE BECAUSE DEFENSE PLACEMENT SYSTEM SUCKS
			-- this prevents cons from wasting time building defenses very far away
			-- a better solution is needed
			utype = nil
			-- p = ai.buildsitehandler:ClosestBuildSpot(builder, builder:GetPosition(), utype)
		end
		if p == nil then
			EchoDebug("did NOT find build spot near turtle position")
			utype = nil
		end
	elseif unitTable[value].isBuilding then
		-- buildings in defended positions
		local turtlePosList = ai.turtlehandler:MostTurtled(builder, value)
		if turtlePosList then
			if #turtlePosList ~= 0 then
				for i, turtlePos in ipairs(turtlePosList) do
					p = ai.buildsitehandler:ClosestBuildSpot(builder, turtlePos, utype)
					if p ~= nil then break end
				end
			end
		end
	end
	-- last ditch placement
	if utype ~= nil and p == nil then
		local builderPos = builder:GetPosition()
		p = ai.buildsitehandler:ClosestBuildSpot(builder, builderPos, utype)
		if p == nil then
			p = map:FindClosestBuildSite(utype, builderPos, 500, 15)
		end
	end
	return utype, value, p
end

function TaskQueueBehaviour:BestFactory()
	local bestScore = -99999
	local bestName, bestPos
	local builder = self.unit:Internal()
	local factoryNames = unitTable[self.name].factoriesCanBuild
	if factoryNames ~= nil then
		for i, factoryName in pairs(factoryNames) do
			local buildMe = true
			local isAdvanced = advFactories[factoryName]
			local isExperimental = expFactories[factoryName] or leadsToExpFactories[factoryName]			
			if ai.needAdvanced and not ai.haveAdvFactory then
				if not isAdvanced then buildMe = false end
			end
			if not ai.needAdvanced then
				if isAdvanced then buildMe = false end
			end
			if ai.needExperimental and not ai.haveExpFactory then
				if not isExperimental then buildMe = false end
			end
			if not ai.needExperimental then
				if expFactories[factoryName] then buildMe = false end
			end
			--[[
			-- this probably isn't a good idea, there are better ways to use up excess metal
			if ai.Metal.income > 10 and ai.Metal.extra > 5 and ai.Metal.full > 0.9 then
				-- don't include built factories if we've got tons of metal
				-- if we include factories we already have, this algo will tend to spit out subpar factories
				if ai.nameCount[factoryName] > 0 then buildMe = false end
			end
			]]--
			if buildMe then
				local utype = game:GetTypeByName(factoryName)
				local builderPos = builder:GetPosition()
				local p
				EchoDebug("looking for most turtled position for " .. factoryName)
				local turtlePosList = ai.turtlehandler:MostTurtled(builder, factoryName)
				if turtlePosList then
					if #turtlePosList ~= 0 then
						for i, turtlePos in ipairs(turtlePosList) do
							p = ai.buildsitehandler:ClosestBuildSpot(builder, turtlePos, utype)
							if p ~= nil then break end
						end
					end
				end
				if p == nil then
					EchoDebug("no turtle position found, trying next to factory")
					local factoryPos = ai.buildsitehandler:ClosestHighestLevelFactory(builder, 10000)
					if factoryPos then
						p = ai.buildsitehandler:ClosestBuildSpot(builder, factoryPos, utype)
					end
				end
				if p == nil then
					EchoDebug("no turtle position found for " .. factoryName .. ", trying near builder")
					p = ai.buildsitehandler:ClosestBuildSpot(builder, builderPos, utype)
				end
				if p ~= nil then
					EchoDebug("found spot for " .. factoryName)
					for mi, mtype in pairs(factoryMobilities[factoryName]) do
						if mtype == "air" or ai.mobRating[mtype] > ai.mobilityRatingFloor then
							local network = ai.maphandler:MobilityNetworkHere(mtype, p)
							if ai.scoutSpots[mtype][network] then
								local numberOfSpots
								if mtype == "air" then
									if factoryName == "armplat" or factoryName == "corplat" then
										-- seaplanes can only build on UW metal
										numberOfSpots = #ai.UWMetalSpots
									else
										-- other aircraft can only build land metal spots and geospots
										numberOfSpots = #ai.landMetalSpots + #ai.geoSpots
									end
								else
									numberOfSpots = #ai.scoutSpots[mtype][network]
								end
								EchoDebug(numberOfSpots .. " spots for " .. factoryName)
								if numberOfSpots > 5 then
									local dist = Distance(builderPos, p)
									local spotPercentage = numberOfSpots / #ai.scoutSpots["air"][1]
									local score = (spotPercentage * ai.maxElmosDiag) - (dist * mobilitySlowMultiplier[mtype])
									score = score * mobilityEffeciencyMultiplier[mtype]
									EchoDebug(factoryName .. " " .. mtype .. " has enough spots (" .. numberOfSpots .. ") and a score of " .. score .. " (" .. spotPercentage .. " " .. dist .. ")")
									if score > bestScore then
										local okay = true
										if okay then
											if mtype == "veh" then
												if ai.maphandler:OutmodedFactoryHere("veh", builderPos) and not ai.maphandler:OutmodedFactoryHere("bot", builderPos) then
													-- don't build a not very useful vehicle plant if a bot factory can be built instead
													okay = false
												end
											end
										end
										if okay then
											if mtype == "bot" and not ai.needExperimental then
												-- don't built a bot lab senselessly to slow us down
												if not ai.maphandler:OutmodedFactoryHere("veh", builderPos) and (ai.nameCount["armvp"] >= 1 or ai.nameCount["corvp"] >= 1) then
													okay = false
												end
											end
										end
										if okay then
											bestScore = score
											bestName = factoryName
											bestPos = p
										end
									end
								end
							end
						end
					end
				end
			end
			-- DebugEnabled = false
		end
	end
	if bestName ~= nil then
		if ai.nameCount[bestName] > 0 then return nil, nil end
		EchoDebug("best factory: " .. bestName)
	end
	return bestPos, bestName
end

function TaskQueueBehaviour:GetQueue()
	self.unit:ElectBehaviour()
	-- fall back to only making enough construction units if a level 2 factory exists
	local got = false
	if wateryTaskqueues[self.name] ~= nil then
		if ai.mobRating["shp"] * 0.5 > ai.mobRating["veh"] then
			q = wateryTaskqueues[self.name]
			got = true
		end
	end
	self.outmodedTechLevel = false
	if outmodedTaskqueues[self.name] ~= nil and not got then
		if self.isFactory and unitTable[self.name].techLevel < ai.maxFactoryLevel and ai.Metal.reserves < ai.Metal.capacity * 0.95 then
			-- stop buidling lvl1 attackers if we have a lvl2, unless we're about to waste metal, in which case use it up
			q = outmodedTaskqueues[self.name]
			got = true
			self.outmodedTechLevel = true
		elseif self.outmodedFactory then
			q = outmodedTaskqueues[self.name]
			got = true
		end
	end
	if not got then
		q = taskqueues[self.name]
	end
	if type(q) == "function" then
		--game:SendToConsole("function table found!")
		q = q(self)
	end
	return q
end

function TaskQueueBehaviour:ConstructionBegun(unitID, unitName, position)
	self.constructing = { unitID = unitID, unitName = unitName, position = position }
end

function TaskQueueBehaviour:ConstructionComplete()
	self.constructing = nil
end

function TaskQueueBehaviour:Update()
	if self.failOut then
		local f = game:Frame()
		if f > self.failOut + 300 then
			-- game:SendToConsole("getting back to work " .. self.name .. " " .. self.id)
			self.failOut = nil
			self.failures = 0
		end
	end
	if not self:IsActive() then
		return
	end
	local f = game:Frame()
	-- econ check
	if f % 22 == 0 then
		GetEcon()
	end
	-- watchdog check
	if not self.constructing and not self.isFactory then
		if (self.lastWatchdogCheck + self.watchdogTimeout < f) or (self.currentProject == nil and (self.lastWatchdogCheck + 1 < f)) then
			-- we're probably stuck doing nothing
			local tmpOwnName = self.unit:Internal():Name() or "no-unit"
			local tmpProjectName = self.currentProject or "empty project"
			if self.currentProject ~= nil then
				EchoDebug("Watchdog: "..tmpOwnName.." abandoning "..tmpProjectName)
				EchoDebug("last watchdog check: "..self.lastWatchdogCheck .. ", watchdog timeout:"..self.watchdogTimeout)
			end
			self:ProgressQueue()
			return
		end
	end
	if self.progress == true then
		self:ProgressQueue()
	end
end

function TaskQueueBehaviour:ProgressQueue()
	self.lastWatchdogCheck = game:Frame()
	self.constructing = false
	self.progress = false
	local builder = self.unit:Internal()
	if not self.released then
		ai.assisthandler:Release(builder)
		ai.buildsitehandler:ClearMyPlans(self)
		if not self.isCommander and not self.isFactory then
			if ai.IDByName[self.id] ~= nil then
				if ai.IDByName[self.id] > ai.nonAssistantsPerName then
					ai.nonAssistant[self.id] = nil
				end
			end
		end
		self.released = true
	end
	if self.queue ~= nil then
		local idx, val = next(self.queue,self.idx)
		self.idx = idx
		if idx == nil then
			self.queue = self:GetQueue(name)
			self.progress = true
			return
		end
		
		local utype = nil
		local value = val

		-- evaluate any functions here, they may return tables
		while type(value) == "function" do
			value = value(self)
		end

		if type(value) == "table" then
			-- not using this
		else
			-- if bigPlasmaList[value] or littlePlasmaList[value] then DebugEnabled = true end -- debugging plasma
			local p
			if value == FactoryUnitName then
				-- build the best factory this builder can build
				p, value = self:BestFactory()
			end
			local success = false
			if value ~= DummyUnitName and value ~= nil then
				EchoDebug(self.name .. " filtering...")
				value = self:CategoryEconFilter(value)
				if value ~= DummyUnitName then
					EchoDebug("before duplicate filter " .. value)
					local duplicate = ai.buildsitehandler:CheckForDuplicates(value)
					if duplicate then value = DummyUnitName end
				end
				EchoDebug(value .. " after filters")
			else
				value = DummyUnitName
			end
			if value ~= DummyUnitName then
				if value ~= nil then
					utype = game:GetTypeByName(value)
				else
					utype = nil
					value = "nil"
				end
				if utype ~= nil then
					if self.unit:Internal():CanBuild(utype) then
						if self.isFactory then
							local helpValue = self:GetHelp(value, self.position)
							if helpValue ~= nil and helpValue ~= DummyUnitName then
								success = self.unit:Internal():Build(utype)
							end
						else
							if p == nil then utype, value, p = self:LocationFilter(utype, value) end
							if utype ~= nil and p ~= nil then
								if type(value) == "table" and value[1] == "ReclaimEnemyMex" then
									EchoDebug("reclaiming enemy mex...")
									--  success = self.unit:Internal():Reclaim(value[2])
									success = CustomCommand(self.unit:Internal(), CMD_RECLAIM, {value[2].unitID})
									value = value[1]
								else
									local helpValue = self:GetHelp(value, p)
									if helpValue ~= nil and helpValue ~= DummyUnitName then
										EchoDebug(utype:Name() .. " has help")
										success = self.unit:Internal():Build(utype, p)
									end
								end
							end
						end
					else
						game:SendToConsole("WARNING: bad taskque: "..self.name.." cannot build "..value)
					end
				else
					game:SendToConsole(self.name .. " cannot build:"..value..", couldnt grab the unit type from the engine")
				end
			end
			-- DebugEnabled = false -- debugging plasma
			if success then
				if self.isFactory then
					if not self.outmodedTechLevel then
						-- factories take up idle assistants
						ai.assisthandler:TakeUpSlack(builder)
					end
				else
					self.target = p
					self.watchdogTimeout = math.max(Distance(self.unit:Internal():GetPosition(), p) * 1.5, 360)
					self.currentProject = value
					if value == "ReclaimEnemyMex" then
						self.watchdogTimeout = self.watchdogTimeout + 450 -- give it 15 more seconds to reclaim it
					else
						ai.buildsitehandler:NewPlan(value, p, self)
					end
				end
				self.released = false
				self.progress = false
				self.failures = 0
			else
				self.target = nil
				self.currentProject = nil
				self.progress = true
				self.failures = (self.failures or 0) + 1
				local limit = 20
				if self.queue then limit = #self.queue end
				if self.failures > limit then
					-- game:SendToConsole("taking a break after " .. limit .. " tries. " .. self.name .. " " .. self.id)
					self.failOut = game:Frame()
					self.unit:ElectBehaviour()
				end
			end
		end
	end
end

function TaskQueueBehaviour:Activate()
	self.active = true
	if self.constructing then
		EchoDebug(self.name .. " " .. self.id .. " resuming construction of " .. self.constructing.unitName .. " " .. self.constructing.unitID)
		-- resume construction if we were interrupted
		local floats = api.vectorFloat()
		floats:push_back(self.constructing.unitID)
		self.unit:Internal():ExecuteCustomCommand(CMD_GUARD, floats)
		self:GetHelp(self.constructing.unitName, self.constructing.position)
		-- self.target = self.constructing.position
		-- self.currentProject = self.constructing.unitName
		self.released = false
		self.progress = false
	else
		self:UnitIdle(self.unit:Internal())
	end
end

function TaskQueueBehaviour:Deactivate()
	self.active = false
	ai.buildsitehandler:ClearMyPlans()
end

function TaskQueueBehaviour:Priority()
	if self.failOut then
		return 0
	elseif self.currentProject == nil then
		return 50
	else
		return 75
	end
end