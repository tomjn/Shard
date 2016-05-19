local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("taskEco: " .. inStr)
	end
end

function NanoTurret()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "cornanotc"
	else
		unitName = "armnanotc"
	end
	return unitName
end

-- MEX

function BuildMex()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "cormex"
	else
		unitName = "armmex"
	end
	return unitName
end

function SpecialMex()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "corexp"
	else
		unitName = "armamex"
	end
	return unitName
end

function BuildMex1()
	local unitName = DummyUnitName
	if ai.Metal.income < 30 then
		unitName = BuildMex()
	else
		unitName = SpecialMex()
	end
	return unitName
end

function BuildUWMex()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "coruwmex"
	else
		unitName = "armuwmex"
	end
	return unitName
end

function BuildMohoMex()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "cormoho"
	else
		unitName = "armmoho"
	end
	return unitName
end

function BuildUWMohoMex()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "coruwmme"
	else
		unitName = "armuwmme"
	end
	return unitName
end

--ENERGY
function Solar()
	if ai.mySide == CORESideName then
		return "corsolar"
	else
		return "armsolar"
	end
end

local function SolarAdv()
	if ai.mySide == CORESideName then
		return "coradvsol"
	else
		return "armadvsol"
	end
end

function Tidal()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "cortide"
	else
		unitName = "armtide"
	end
	return unitName
end

function Wind()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "corwin"
	else
		unitName = "armwin"
	end
	return unitName
end

function TidalIfTidal()
	local unitName = DummyUnitName
	EchoDebug("tidal power is " .. tidalPower)
	if tidalPower >= 10 then
		unitName = Tidal()
	end
	return unitName
end

function WindSolar()
	local unitName = DummyUnitName
	local wind = false
	if needWind then
		if windRatio == 1 then
			wind = true
		else
			local r = math.random()
			if r < windRatio then wind = true end
		end
	end
	if wind then
		unitName = Wind()
	else
		unitName = Solar()
	end
	return unitName
end

function Energy1()
	local unitName=DummyUnitName
	local wind = needWind and ((windRatio == 1) or (math.random() < windRatio))
	if ai.Energy.income > 150 then --and ai.Metal.reserves >50
		unitName = SolarAdv()
	elseif wind then
		unitName = Wind()
	else
		unitName = Solar()
	end
	return unitName
end

function BuildGeo()
	-- don't attempt if there are no spots on the map
	EchoDebug("BuildGeo " .. tostring(ai.mapHasGeothermal))
	if not ai.mapHasGeothermal or ai.Energy.income < 150 or ai.Metal.income < 10 then
		return DummyUnitName
	end
	if ai.mySide == CORESideName then
		return "corgeo"
	else
		return "armgeo"
	end
end

function BuildMohoGeo()
	EchoDebug("BuildMohoGeo " .. tostring(ai.mapHasGeothermal))
	-- don't attempt if there are no spots on the map
	if not ai.mapHasGeothermal or ai.Energy.income < 900 or ai.Metal.income < 24 then
		return DummyUnitName
	end
	if ai.mySide == CORESideName then
		return "cmgeo"
	else
		return "amgeo"
	end
	-- will turn into a safe geothermal or a geothermal plasma battery if too close to a factory
end

local function BuildSpecialGeo()
	-- don't attempt if there are no spots on the map
	if not ai.mapHasGeothermal then
		return DummyUnitName
	end
	if ai.mySide == CORESideName then
		return "corbhmt"
	else
		return "armgmm"
	end
end

local function BuildFusion()
	if ai.mySide == CORESideName then
		return "corfus"
	else
		return "armfus"
	end
	-- will become cafus and aafus in CategoryEconFilter in TaskQueueBehaviour if energy income is higher than 4000
end

local function BuildAdvFusion()
	if ai.mySide == CORESideName then
		return "cafus"
	else
		return "aafus"
	end
	-- will become cafus and aafus in CategoryEconFilter in TaskQueueBehaviour if energy income is higher than 4000
end

local function BuildAdvEnergy(self)
	print(tostring('advname '..self.name))
	local unitName = DummyUnitName
	unitName = BuildFusion()
	if ai.Energy.income > 3000 and (self.name == 'armacv' or self.name == 'coracv') then
		unitName = BuildAdvFusion()
	end
	return unitName
end
			

local function BuildUWFusion()
	if ai.mySide == CORESideName then
		return "coruwfus"
	else
		return "armuwfus"
	end
end

-- build conversion or storage
function DoSomethingForTheEconomy(self)
	local highEnergy = ai.Energy.full > 0.9
	local lowEnergy = ai.Energy.full < 0.1
	local highMetal = ai.Metal.full > 0.9
	local lowMetal = ai.Metal.full < 0.1
	local isWater = unitTable[self.unit:Internal():Name()].needsWater
	local unitName = DummyUnitName
	-- maybe we need conversion?
	if ai.Energy.extra > 80 and highEnergy and lowMetal and ai.Metal.extra < 0 and ai.Energy.income > 300 then
		local converterLimit = math.min(math.floor(ai.Energy.income / 200), 4)
		if isWater then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("corfmkr", converterLimit)
			else
				unitName = BuildWithLimitedNumber("armfmkr", converterLimit)
			end		
		else
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("cormakr", converterLimit)
			else
				unitName = BuildWithLimitedNumber("armmakr", converterLimit)
			end
		end
	end
	-- maybe we need storage?
	if unitName == DummyUnitName then
		-- energy storage
		if ai.Energy.extra > 150 and highEnergy and not lowMetal then
			if isWater then
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("coruwes", 2)
				else
					unitName = BuildWithLimitedNumber("armuwes", 2)
				end	
			else
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("corestor", 2)
				else
					unitName = BuildWithLimitedNumber("armestor", 2)
				end
			end
		end
	end
	if unitName == DummyUnitName then
		-- metal storage
		if ai.Metal.extra > 5 and highMetal and highEnergy then
			if isWater then
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("coruwms", 2)
				else
					unitName = BuildWithLimitedNumber("armuwms", 2)
				end	
			else
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("cormstor", 2)
				else
					unitName = BuildWithLimitedNumber("armmstor", 2)
				end
			end
		end
	end

	return unitName
end


-- build advanced conversion or storage
function DoSomethingAdvancedForTheEconomy(self)
	local highEnergy = ai.Energy.full > 0.9
	local lowEnergy = ai.Energy.full < 0.1
	local highMetal = ai.Metal.full > 0.9
	local lowMetal = ai.Metal.full < 0.1
	local unitName = self.unit:Internal():Name()
	local isWater = unitTable[unitName].needsWater or seaplaneConList[unitName]
	local unitName = DummyUnitName
	-- maybe we need conversion?
	if ai.Energy.extra > 800 and highEnergy and lowMetal and ai.Metal.extra < 0 and ai.Energy.income > 2000 then
		local converterLimit = math.floor(ai.Energy.income / 1000)
		if isWater then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("corfmmm", converterLimit)
			else
				unitName = BuildWithLimitedNumber("armfmmm", converterLimit)
			end		
		else
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("cormmkr", converterLimit)
			else
				unitName = BuildWithLimitedNumber("armmmkr", converterLimit)
			end
		end
	end
	-- building big storage is a waste
	--[[
	-- maybe we need storage?
	if unitName == DummyUnitName then
		-- energy storage
		if ai.Energy.extra > 1500 and highEnergy and not lowMetal then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("coruwadves", 1)
			else
				unitName = BuildWithLimitedNumber("armuwadves", 1)
			end	
		end
	end
	if unitName == DummyUnitName then
		-- metal storage
		if ai.Metal.extra > 25 and highMetal and highEnergy then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("coruwadvms", 1)
			else
				unitName = BuildWithLimitedNumber("armuwadvms", 1)
			end	
		end
	end
	]]--

	return unitName
end

function buildEstore1()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "corestor"
	else
		unitName = "armestor"
	end
	return unitName
end

function buildEstore2()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "coruwadves"
	else
		unitName = "armuwadves"
	end
	return unitName	
end

function buildMstore1()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
			unitName = "cormstor"
	else
			unitName = "armmstor"
	end
	return unitName
end

function buildMstore2()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "coruwadvms"
	else
		unitName = "armuwadvms"
	end
	return unitName
end

function buildMconv1()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "cormakr"	
	else
		unitName = "armmakr"
	end
	return unitName
end

function buildMconv2()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
			unitName ='cormmkr'
	else
			unitName ='armmmkr'
	end
	return unitName
end

function buildMconv2UW()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
			unitName ='corfmmm'
	else
			unitName ='armfmmm'
	end
	return unitName
end

function buildWEstore1()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "coruwes"
	else
		unitName = "armuwes"
	end
	return unitName
end

function buildWMstore1()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "coruwms"
	else
		unitName = "armuwms"
	end
	return unitName
end

function buildWMconv1()
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = "corfmkr"	
	else
		unitName = "armfmkr"
	end
	return unitName
end

function Economy0()
	local unitName=DummyUnitName
	if ai.Energy.full > 0.1 and (ai.Metal.income < 1 or ai.Metal.full < 0.3) then
		unitName = BuildMex()
	-- elseif ai.Energy.full > 0.9 and ai.Energy.income > 100  and ai.Metal.reserves > 100 and ai.Energy.capacity < 7000 then
		-- unitName = buildEstore1()
	-- elseif ai.Metal.full > 0.7 and ai.Metal.income > 10 and ai.Metal.capacity < 7000  then
		-- unitName = buildMstore1()
	elseif ai.Energy.full > 0.9 and ai.Energy.income > 200 and ai.Energy.income < 1500 and ai.Metal.full < 0.5 then
		unitName = buildMconv1()
	elseif (ai.Energy.full < 0.5 or ai.Energy.income < ai.Energy.usage)   then
		unitName = WindSolar()
	else
		unitName = BuildMex()
	end
	EchoDebug('Economy commander '..unitName)
	return unitName
end

function AdvEconomy(self)
	local unitName=DummyUnitName
	-- if ai.Energy.full > 0.9 and ai.Energy.income > 1000 and ai.Metal.income > ai.Metal.usage and ai.Energy.capacity < 40000 then
		-- unitName = buildEstore2()
	-- elseif ai.Metal.full > 0.8 and ai.Metal.income > 30 and ai.Metal.capacity < 20000 then
		-- unitName = buildMstore2()
	if ai.Energy.full > 0.9 and ai.Energy.income > 1500 and ai.Metal.full < 0.5 then
		unitName = buildMconv2()
	elseif (ai.Energy.full < 0.3 or ai.Energy.income < ai.Energy.usage*1.1) and ai.Metal.full > 0.1 and ai.Metal.income > 18 then
		unitName = BuildAdvEnergy(self)
	else--if ai.Metal.full < 0.2 and ai.Energy.full > 0.1 then
		unitName = BuildMohoMex()
	end
	EchoDebug('Economy level 3 '..unitName)
	return unitName
end

function Economy1()
        local unitName=DummyUnitName
	if ai.Energy.full > 0.5 and ai.Metal.full > 0.1 and ai.Metal.full < 0.5 and ai.Metal.income > 30 then
		unitName = SpecialMex()
	elseif (ai.Energy.full > 0.5  and ai.Metal.full > 0.3 and ai.Metal.income > 10 and ai.Energy.income > 100) then -- or (ai.Energy.income > ai.Energy.usage*1.1 and ai.Metal.income > ai. Metal.usage*1.1)then
		unitName = NanoTurret()
	-- elseif 	ai.Energy.full > 0.9 and ai.Energy.income > 100 and ai.Metal.reserves > 250 and ai.Energy.capacity < 7000 then
		-- unitName = buildEstore1()
	-- elseif ai.Metal.full > 0.8 and ai.Metal.income > 10 and ai.Metal.capacity < 7000  then
		-- unitName = buildMstore1()
	elseif ai.Energy.full > 0.9 and ai.Energy.income > 200 and ai.Energy.income < 1500 and ai.Metal.full < 0.5 then
		unitName = buildMconv1()
	elseif (ai.Energy.full < 0.3 or ai.Energy.income < ai.Metal.usage) and ai.Metal.full > 0.1 then
		unitName = Energy1()
	else
		unitName = BuildMex()
	end
	EchoDebug('Economy level 1 '..unitName)
	return unitName
end

function EconomyUnderWater()
	local unitName = DummyUnitName
	if ai.Energy.full > 0.9 and ai.Energy.income > 100  and ai.Metal.reserves > 100 and ai.Energy.capacity < 7000 then
		unitName = buildWEstore1()
	elseif ai.Metal.full > 0.7 and ai.Metal.income > 10 and ai.Metal.capacity < 7000 then
		unitName = buildWMstore1()
	elseif ai.Energy.full > 0.8 and ai.Energy.income > 50 then
		unitName = buildWMconv1()
	elseif ai.Energy.full > 0.1 and (ai.Metal.income < 1 or ai.Metal.full < 0.6) then
		unitName = BuildUWMex()
	elseif (ai.Energy.full < 0.3 or ai.Energy.income < ai.Metal.usage) and ai.Metal.income > 3 and ai.Metal.full > 0.1 then
		unitName = TidalIfTidal()--this can get problems
	else
		unitName = BuildUWMex()
	end
	EchoDebug('Under water Economy level 1 '..unitName)
	return unitName
end
function AdvEconomyUnderWater(self)
	local unitName=DummyUnitName
	if 	ai.Energy.full>0.9 and ai.Energy.income>1000 and ai.Metal.income>ai.Metal.usage and ai.Energy.capacity < 100000  then
		unitName=buildEstore2(self)
	elseif ai.Metal.full>0.7 and ai.Metal.income>30 and ai.Metal.capacity < 50000 then
		unitName=buildMstore2(self)
	elseif ai.Energy.full>0.8  then
		unitName=buildMconv2UW(self)
	elseif ai.Energy.full>0.2 then
		unitName=BuildUWMohoMex()
	elseif (ai.Energy.full<0.3 or ai.Energy.income<ai.Metal.usage) and ai.Metal.full>0.1 then
		unitName=BuildUWFusion(self)
	end
	EchoDebug('Economy under water level 2 '..unitName)
	return unitName
end

function EconomySeaplane(self)
	local unitName=DummyUnitName
	if 	ai.Energy.full>0.9 and ai.Energy.income>1000 and ai.Metal.income>ai.Metal.usage and ai.Energy.capacity < 100000  then
		unitName=buildEstore2(self)
	elseif ai.Metal.full>0.7 and ai.Metal.income>30 and ai.Metal.capacity < 50000 then
		unitName=buildMstore2(self)
	elseif ai.Energy.full>0.8  then
		unitName=buildMconv2UW(self)
	elseif ai.Energy.full>0.5 and ai.Metal.full>0.5 then
		unitName=Lvl2ShipAssist() 
	end
	EchoDebug('Economy Seaplane '..unitName)
	return unitName
end

function EconomyBattleEngineer(self)
        local unitName=DummyUnitName
	if ai.Energy.full > 0.5  and ai.Metal.full > 0.3 and ai.Metal.income > 10 and ai.Energy.income > 100 then
		unitName= NanoTurret()
	elseif ai.Energy.full < 0.1 and ai.Metal.full > 0.3 then
		unitName = Solar()
	elseif ai.Metal.full < 0.2 then 
		unitName=BuildMex()
	else
		unitName = EngineerAsFactory()
	end
	EchoDebug('Economy battle engineer  '..unitName)
	return unitName
end

function EconomyNavalEngineer(self)
        local unitName=DummyUnitName
	if ai.Energy.full < 0.2 and ai.Metal.income > ai.Metal.usage*1.1 and ai.Metal.full > 0.2 then
		unitName = TidalIfTidal()
	elseif ai.Metal.full < 0.2 and ai.Energy.income > ai.Metal.usage and ai.Energy.full > 0.2 then
		unitName = BuildUWMex()
	else
		unitName = NavalEngineerAsFactory()
	end
	EchoDebug('Economy Naval Engineer '..unitName)
	return unitName
end

function EconomyFark(self)
	local unitName = DummyUnitName
	if (ai.Energy.full < 0.5 or ai.Energy.income < ai.Energy.usage)   then
		unitName = WindSolar()
	elseif ai.Energy.full > 0.9 then
		unitName = buildEstore1()
	else
		unitName = BuildMex()
	end
	return unitName
end