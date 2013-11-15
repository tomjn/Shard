require "unitlists"
require "unittable"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("TaskQueueBehaviour: " .. inStr)
	end
end

local Energy, Metal, extraEnergy, extraMetal, energyTooLow, energyOkay, metalTooLow, metalOkay, metalBelowHalf, metalAboveHalf, notEnoughCombats, farTooFewCombats

local currentProjects = {}

local function GetEcon()
	Energy = game:GetResourceByName("Energy")
	Metal = game:GetResourceByName("Metal")
	extraEnergy = Energy.income - Energy.usage
	extraMetal = Metal.income - Metal.usage
	local enoughMetalReserves = math.min(Metal.income * 2, Metal.capacity * 0.1)
	local lotsMetalReserves = math.min(Metal.income * 10, Metal.capacity * 0.5)
	local enoughEnergyReserves = math.min(Energy.income * 2, Energy.capacity * 0.25)
	-- local lotsEnergyReserves = math.min(Energy.income * 3, Energy.capacity * 0.5)
	energyTooLow = Energy.reserves < enoughEnergyReserves or Energy.income < 40
	energyOkay = Energy.reserves >= enoughEnergyReserves and Energy.income >= 40
	metalTooLow = Metal.reserves < enoughMetalReserves
	metalOkay = Metal.reserves >= enoughMetalReserves
	metalBelowHalf = Metal.reserves < lotsMetalReserves
	metalAboveHalf = Metal.reserves >= lotsMetalReserves
	notEnoughCombats = ai.combatCount < 13
	farTooFewCombats = ai.combatCount < 5
end

-- prevents duplication of expensive buildings
local function DuplicateFilter(builder, value)
	if value == nil then return DummyUnitName end
	if value == DummyUnitName then return DummyUnitName end
	EchoDebug(value .. " before duplicate filter")
	if unitTable[value].isBuilding and unitTable[value].buildOptions then
		-- don't build two factories at once
		for uid, v in pairs(currentProjects) do
			if uid ~= buid and unitTable[v].isBuilding and unitTable[v].buildOptions then return DummyUnitName end
		end
		return value
	end
	local utable = unitTable[value]
	if utable.isBuilding and utable.metalCost > 300 then
		local buid = builder:ID()
		for uid, v in pairs(currentProjects) do
			if uid ~= buid and v == value then return DummyUnitName end
		end
	end
	return value
end

-- keeps amphibious/hover cons from zigzagging from the water to the land
local function LandWaterFilter(builder, value)
	if value == nil then return DummyUnitName end
	if value == DummyUnitName then return DummyUnitName end
	EchoDebug(value .. " (before landwater filter)")
	if value == "armmex" or value == "cormex" or value == "armmohomex" or value == "cormohomex" or value == "armsy" or value == "corsy" then
		-- leave these alone, these are dealt with at the time of finding a spot for them
		return value
	end
	local bmtype = ai.maphandler:MobilityOfUnit(builder)
	local bname = builder:Name()
	if bmtype == "amp" or bmtype == "hov" or bname == "armcom" or bname == "corcom" then
		-- only check if the unit goes on both land and water
		local bpos = builder:GetPosition()
		if unitTable[value].needsWater then
			-- water
			if ai.maphandler:MobilityNetworkHere("shp", bpos) ~= nil then
				return value
			else
				return DummyUnitName
			end
		else
			-- land
			if ai.maphandler:MobilityNetworkHere("bot", bpos) ~= nil then
				return value
			else
				return DummyUnitName
			end
		end
	else
		-- if builder is limited to land or water, don't bother checking
		return value
	end
end

TaskQueueBehaviour = class(Behaviour)

function TaskQueueBehaviour:CategoryEconFilter(value)
	if value == nil then return DummyUnitName end
	if value == DummyUnitName then return DummyUnitName end
	EchoDebug(value .. " (before econ filter)")
	-- EchoDebug("Energy: " .. Energy.reserves .. " " .. Energy.capacity .. " " .. Energy.income .. " " .. Energy.usage)
	-- EchoDebug("Metal: " .. Metal.reserves .. " " .. Metal.capacity .. " " .. Metal.income .. " " .. Metal.usage)
	if nanoTurretList[value] then
		-- nano turrets
		EchoDebug(" nano turret")
		if metalBelowHalf or energyTooLow or farTooFewCombats then
			value = DummyUnitName
		end
	elseif reclaimerList[value] then
		-- dedicated relcimaer
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
			if energyTooLow and Metal.income > 3 then
				value = DummyUnitName
			end
		elseif value == "corwin" or value == "armwin" or value == "cortide" or value == "armtide" or (unitTable[value].totalEnergyOut > 0 and not unitTable[value].buildOptions) then
			-- energy plant
			EchoDebug("  energy plant")
			if energyOkay or metalTooLow then
				value = DummyUnitName
			elseif self.name == "coracv" and value == "corfus" and Energy.income > 4000 then
				-- build advanced fusion
				value = "cafus"
			elseif self.name == "armacv" and value == "armfus" and Energy.income > 4000 then
				-- build advanced fusion
				value = "aafus"
			end
		elseif unitTable[value].buildOptions ~= nil then
			-- factory
			EchoDebug("  factory")
			EchoDebug(ai.factories)
			if ai.factories - ai.outmodedFactories <= 0 and metalOkay and energyOkay and Metal.income > 3 and Metal.reserves > unitTable[value].metalCost * 0.7 then
				EchoDebug("   first factory")
				-- build the first factory
			elseif (advFactories[value] or expFactories[value]) and metalOkay and energyOkay then
				-- build advanced or experimental factory
			elseif ai.couldAttack - ai.factories >= 1 or ai.couldBomb - ai.factories >= 1 then
				-- other factory after attack
				if metalTooLow or Metal.income < ai.factories * 10 or energyTooLow or Energy.income < 250 or (ai.needAdvanced and not ai.haveAdvFactory) then
					value = DummyUnitName
				end
			else
				-- other factory
				if metalBelowHalf or Metal.income < ai.factories * 14 or energyTooLow or Energy.income < 350 or notEnoughCombats or (ai.needAdvanced and not ai.haveAdvFactory) then
					value = DummyUnitName
				end
			end
		elseif unitTable[value].isWeapon then
			-- defense
			EchoDebug("  defense")
			if bigPlasmaList[value] or nukeList[value] then
				-- long-range plasma and nukes aren't really defense
				if metalTooLow or energyTooLow or Metal.income < 35 or ai.factories == 0 or notEnoughCombats then
					value = DummyUnitName
				end
			elseif littlePlasmaList[value] then
				-- plasma turrets need units to back them up
				if metalTooLow or energyTooLow or Metal.income < 12 or ai.factories == 0 or notEnoughCombats then
					value = DummyUnitName
				end
			else
				if metalTooLow or Metal.income < (unitTable[value].metalCost / 35) + 2 or energyTooLow or ai.factories == 0 then
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
			if notEnoughCombats or metalTooLow or energyTooLow or Energy.income < 200 or Metal.income < 8 or ai.factories == 0 then
				value = DummyUnitName
			end
		end
	else
		-- moving units
		EchoDebug(" moving unit")
		if unitTable[value].buildOptions ~= nil then
			-- construction unit
			EchoDebug("  construction unit")
			if (ai.totalCons[value] == nil or ai.totalCons[value] == 0) and metalOkay and energyOkay and (self.outmodedFactory or not farTooFewCombats) then
				-- build at least one of each type
			else
				local airfactory = false
				for i, name in pairs(airFacList) do
					if name == self.name then
						airfactory = true
						break
					end
				end
				EchoDebug(ai.combatCount .. " " .. ai.conCount .. " " .. tostring(metalBelowHalf) .. " " .. tostring(energyTooLow))
				if metalBelowHalf or energyTooLow or (ai.combatCount < ai.conCount * 5 and not self.outmodedFactory and not airfactory) then
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
	if ai.totalCons == nil then ai.totalCons = {} end
	if ai.outmodedFactories == nil then ai.outmodedFactories = 0 end

	GetEcon()
	self.active = false
	self.currentProject = nil
	self.reclaiming = false
	self.reclaimStart = 0
	self.lastWatchdogCheck = game:Frame()
	local u = self.unit:Internal()
	local mtype, network = ai.maphandler:MobilityOfUnit(u)
	self.mtype = mtype
	self.name = u:Name()
	self.id = u:ID()

	-- register if factory is going to use outmoded queue
	if factoryMobilities[self.name] ~= nil then
		local upos = u:GetPosition()
		for i, mtype in pairs(factoryMobilities[self.name]) do
			if mtype ~= nil then
				if ai.maphandler:OutmodedFactoryHere(mtype, upos) then
					self.outmodedFactory = true
					ai.outmodedFactoryID[self.id] = true
					ai.outmodedFactories = ai.outmodedFactories + 1
					ai.outmodedFactories = 1
					break
				end
			end
		end
	end

	self.countdown = 0
	if self:HasQueues() then
		self.queue = self:GetQueue()
	end
	
	self.waiting = {}
end

function TaskQueueBehaviour:HasQueues()
	return (taskqueues[self.name] ~= nil)
end

function TaskQueueBehaviour:UnitCreated(unit)
	if unit.engineID == self.unit.engineID then

	end
end

function TaskQueueBehaviour:UnitBuilt(unit)
	if not self:IsActive() then
		return
	end
	if self.unit == nil then return end
	if unit.engineID == self.unit.engineID then
		self.progress = true
	end
end

function TaskQueueBehaviour:UnitIdle(unit)
	if not self:IsActive() then
		return
	end
	if self.unit == nil then return end
	if unit.engineID == self.unit.engineID then
		self.progress = true
		self.countdown = 0
		self.currentProject = nil
		self.reclaiming = false
		self.reclaimLeft = 0
		currentProjects[self.unit:Internal():ID()] = nil
		self.unit:ElectBehaviour()
	end
end

function TaskQueueBehaviour:UnitDead(unit)
	if self.unit ~= nil then
		if unit.engineID == self.unit.engineID then
			-- game:SendToConsole("taskqueue-er " .. self.name .. " died")
			if self.outmodedFactory then ai.outmodedFactories = ai.outmodedFactories - 1 end
			-- self.unit = nil
			if self.target then ai.targethandler:AddBadPosition(self.target, self.mtype) end
			currentProjects[self.id] = nil
			ai.assisthandler:Release(nil, self.id, true)
			if self.waiting ~= nil then
				for k,v in pairs(self.waiting) do
					ai.modules.sleep.Kill(self.waiting[k])
				end
			end
			self.waiting = nil
		end
	end
end

function TaskQueueBehaviour:GetHelp(value)
	if value == nil then return DummyUnitName end
	if value == DummyUnitName then return DummyUnitName end
	EchoDebug(value .. " before getting help")
	local builder = self.unit:Internal()
	if helpList[value] then
		local hashelp = ai.assisthandler:PersistantSummon(builder, helpList[value], 1)
		if hashelp then
			return value
		end
	elseif unitTable[value].isBuilding and unitTable[value].buildOptions then
		if ai.factories == 0 then
			ai.assisthandler:Summon(builder)
			ai.assisthandler:Magnetize(builder)
			return value
		else
			local hashelp = ai.assisthandler:Summon(builder, ai.factories)
			if hashelp then
				ai.assisthandler:Magnetize(builder)
				return value
			end
		end
	else
		local number
		if unitTable[self.name].isBuilding then
			-- factories have more nano output
			number = math.floor((unitTable[value].metalCost + 1000) / 1500)
		else
			number = math.floor((unitTable[value].metalCost + 750) / 1000)
		end
		if number == 0 then return value end
		local hashelp = ai.assisthandler:Summon(builder, number)
		if hashelp then return value end
	end
	return DummyUnitName
end

function TaskQueueBehaviour:LocationFilter(utype, value)
	if unitTable[self.name].isBuilding then return utype, value end -- factories don't need to look for build locations
	local p
	local builder = self.unit:Internal()
	if unitTable[value].extractsMetal > 0 then
		-- metal extractor
		local uw
		p, uw = ai.maphandler:ClosestFreeSpot(utype, builder)
		if p ~= nil then
			EchoDebug("extractor spot: " .. p.x .. ", " .. p.z)
			if uw then
				EchoDebug("underwater extractor " .. uw:Name())
				utype = uw
			end
		else
			utype = nil
		end
	elseif geothermalPlant[value] then
		-- geothermal
		local builderPos = builder:GetPosition()
		p = map:FindClosestBuildSite(utype, builderPos, 5000, 0)
		if p ~= nil then
			-- don't build on geo spots that units can't get to
			if ai.maphandler:UnitCanGoHere(builder, p) then
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
		else
			utype = nil
		end
	elseif nanoTurretList[value] then
		-- build nano turrets next to a factory near you
		EchoDebug("looking for factory for nano")
		local factoryPos = ai.buildsitehandler:ClosestHighestLevelFactory(builder, 5000)
		if factoryPos ~= nil then
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
	elseif unitTable[value].isBuilding and unitTable[value].buildOptions then
		-- build factories next to a nano turret near you
		EchoDebug("looking for nano to build factory next to")
		local nano = ai.buildsitehandler:ClosestNanoTurret(builder, 3000)
		if nano ~= nil then
			local nanoPos = nano:GetPosition()
			p = ai.buildsitehandler:ClosestBuildSpot(builder, nanoPos, utype)
		end
		if p == nil then
			EchoDebug("no nano found for factory, trying a turtle position")
			local turtlePos = ai.turtlehandler:MostTurtled(builder)
			if turtlePos then
				p = ai.buildsitehandler:ClosestBuildSpot(builder, turtlePos, utype)
			else
				EchoDebug("no turtle position found, building wherever")
				local builderPos = builder:GetPosition()
				p = ai.buildsitehandler:ClosestBuildSpot(builder, builderPos, utype)
			end
		end
	elseif shieldList[value] or antinukeList[value] or unitTable[value].jammerRadius ~= 0 or unitTable[value].radarRadius ~= 0 or unitTable[value].sonarRadius ~= 0 or (unitTable[value].isWeapon and unitTable[value].isBuilding and not nukeList[value] and not bigPlasmaList[value] and not littlePlasmaList[value]) then
		-- shields, defense, antinukes, jammer towers, radar, and sonar
		EchoDebug("looking for least turtled position")
		local turtlePos = ai.turtlehandler:LeastTurtled(builder, value)
		if turtlePos then
			EchoDebug("found turtle position")
			p = ai.buildsitehandler:ClosestBuildSpot(builder, turtlePos, utype)
			if p == nil then
				EchoDebug("did NOT find build spot near turtle position")
				utype = nil
			end
		else
			utype = nil
		end
	elseif unitTable[value].isBuilding then
		-- buildings in defended positions
		local bombard = false
		if nukeList[value] or bigPlasmaList[value] or littlePlasmaList[value] then
			bombard = value
		end
		local turtlePos = ai.turtlehandler:MostTurtled(builder, bombard)
		if turtlePos then
			p = ai.buildsitehandler:ClosestBuildSpot(builder, turtlePos, utype)
		else
			if bombard then
				utype = nil
			else
				local builderPos = builder:GetPosition()
				p = ai.buildsitehandler:ClosestBuildSpot(builder, builderPos, utype)
			end
		end
	else
		local builderPos = builder:GetPosition()
		p = ai.buildsitehandler:ClosestBuildSpot(builder, builderPos, utype)
	end
	return utype, value, p
end

function TaskQueueBehaviour:GetQueue()
	self.unit:ElectBehaviour()
	-- fall back to only making enough construction units if a level 2 factory exists
	local got = false
	if wateryTaskqueues[self.name] ~= nil then
		if ai.mobRating["shp"] > ai.mobRating["veh"] * 0.5 then
			q = wateryTaskqueues[self.name]
			got = true
		end
	end
	self.outmodedTechLevel = false
	if outmodedTaskqueues[self.name] ~= nil and not got then
		if unitTable[self.name].isBuilding and unitTable[self.name].techLevel < ai.maxFactoryLevel then
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

function TaskQueueBehaviour:Update()
	if not self:IsActive() then
		return
	end
	local f = game:Frame()
	-- econ check
	if f % 22 == 0 then
		GetEcon()
	end
	-- watchdog check
	if (self.lastWatchdogCheck + 8000 < f) or (self.currentProject == nil and (self.lastWatchdogCheck + 1 < f)) or (hyperWatchdog[self.currentProject] and self.lastWatchdogCheck + 3000 < f) then
		-- maybe we're doing something important?
		local dontInterrupt = false
		for _, uname in pairs(dontInterruptList) do
			if uname == self.currentProject then
				dontInterrupt = true
				break
			end
		end
		if not dontInterrupt then
			-- we're probably stuck doing nothing
			local tmpOwnName = self.unit:Internal():Name() or "no-unit"
			local tmpProjectName = self.currentProject or "empty project"
			if self.currentProject ~= nil then
				EchoDebug("Watchdog: "..tmpOwnName.." abandoning "..tmpProjectName)
			end
			self:ProgressQueue()
			return
		end
	end
	local s = self.countdown
	if self.reclaiming then
		self.reclaimLeft = self.reclaimLeft - 1
	end
	if self.progress == true then
		if (ai.tqblastframe ~= f) or (ai.tqblastframe == nil) or (self.countdown == 15) then
			self.countdown = 0
			ai.tqblastframe = f
			self:ProgressQueue()
			return
		else
			if self.countdown == nil then
				self.countdown = 1
			else
				self.countdown = self.countdown + 1
			end
		end
		if self.reclaiming and (self.reclaimLeft <= 0) then
			self.reclaiming = false
			self.reclaimLeft = 0
			self:ProgressQueue()
			return
		end
	end
end
TaskQueueWakeup = class(function(a,tqb)
	a.tqb = tqb
end)
function TaskQueueWakeup:wakeup()
	game:sendtoconsole("advancing queue from sleep1")
	self.tqb:ProgressQueue()
end

function TaskQueueBehaviour:ProgressQueue()
	self.lastWatchdogCheck = game:Frame()
	self.progress = false
	self.reclaiming = false
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
			local builder = self.unit:Internal()
			if not self.released then
				ai.assisthandler:Release(builder)
				self.released = true
			end
			if value ~= DummyUnitName then
				EchoDebug(self.name .. " filtering...")
				value = DuplicateFilter(builder, value)
				value = LandWaterFilter(builder, value)
				value = self:CategoryEconFilter(value)
				value = self:GetHelp(value)
				self.released = false
				EchoDebug(value .. " after filters")
			end
			if value ~= DummyUnitName then
				if unitTable[self.name].isBuilding and not self.outmodedTechLevel then
					-- factories take up idle assistants
					ai.assisthandler:TakeUpSlack(builder)
				end
				if value ~= nil then
					utype = game:GetTypeByName(value)
				else
					utype = nil
					value = "nil"
				end
				local success = false
				if utype ~= nil then
					if self.unit:Internal():CanBuild(utype) then
						local p
						utype, value, p = self:LocationFilter(utype, value)
						if utype ~= nil then
							self.target = p
							if p == nil then
								success = self.unit:Internal():Build(utype)
							else
								success = self.unit:Internal():Build(utype, p)
							end
							self.progress = not success
						else
							self.progress = true
							EchoDebug("location filter blocked " .. self.name .. " from building " .. value)
						end
					else
						self.progress = true
						game:SendToConsole("WARNING: bad taskque: "..self.name.." cannot build "..value)
					end
				else
					game:SendToConsole(self.name .. " cannot build:"..value..", couldnt grab the unit type from the engine")
					self.progress = true
				end
				if success then
					self.currentProject = value
					currentProjects[self.unit:Internal():ID()] = value
				else
					self.currentProject = nil
				end
			else
				self.progress = true
				self.currentProject = nil
			end
		end
	end
end

function TaskQueueBehaviour:Activate()
	self.progress = true
	self.active = true
end

function TaskQueueBehaviour:Deactivate()
	self.active = false
	currentProjects[self.id] = nil
end

function TaskQueueBehaviour:Priority()
	if self.currentProject == nil then
		return 50
	else
		return 75
	end
end