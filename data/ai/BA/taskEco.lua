--Factory call
function BuildAppropriateFactory(tskqbhvr)
	return FactoryUnitName
end
--nano call
function NanoTurret(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cornanotc"
	else
		unitName = "armnanotc"
	end
	return unitName
end

-- MEX

function BuildMex(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cormex"
	else
		unitName = "armmex"
	end
	return unitName
end

function SpecialMex(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corexp"
	else
		unitName = "armamex"
	end
	return unitName
end

function BuildUWMex(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "coruwmex"
	else
		unitName = "armuwmex"
	end
	return unitName
end

function BuildMohoMex(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cormoho"
	else
		unitName = "armmoho"
	end
	return unitName
end

function BuildUWMohoMex(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "coruwmme"
	else
		unitName = "armuwmme"
	end
	return unitName
end

--ENERGY
function Solar(tskqbhvr)
	if MyTB.side == CORESideName then
		return "corsolar"
	else
		return "armsolar"
	end
end

local function SolarAdv(tskqbhvr)
	if MyTB.side == CORESideName then
		return "coradvsol"
	else
		return "armadvsol"
	end
end

function Tidal(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cortide"
	else
		unitName = "armtide"
	end
	return unitName
end

function Wind(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corwin"
	else
		unitName = "armwin"
	end
	return unitName
end

function TidalIfTidal(tskqbhvr)
	local unitName = DummyUnitName
	local tidalPower = tskqbhvr.ai.map:TidalStrength()
	tskqbhvr:EchoDebug("tidal power is " .. tidalPower)
	if tidalPower >= 10 then
		unitName = Tidal()
	end
	return unitName
end

function windLimit(tskqbhvr)
	if tskqbhvr.ai.map:AverageWind() >= 10 then
		local minWind = tskqbhvr.ai.map:MinimumWindSpeed()
		if minWind >= 8 then
			tskqbhvr:EchoDebug("minimum wind high enough to build only wind")
			return true
		else
			return math.random() < math.max(0.5, minWind / 8)
		end
	else
		return false
	end
end

function WindSolar(tskqbhvr)
	if windLimit(tskqbhvr) then
		return Wind()
	else
		return Solar()
	end
end

function Energy1(tskqbhvr)
	if tskqbhvr.ai.Energy.income > math.max( tskqbhvr.ai.map:AverageWind() * 20, 150) then --and tskqbhvr.ai.Metal.reserves >50
		return SolarAdv(tskqbhvr)
	else
		return WindSolar(tskqbhvr)
	end
end

function BuildGeo(tskqbhvr)
	-- don't attempt if there are no spots on the map
	tskqbhvr:EchoDebug("BuildGeo " .. tostring(tskqbhvr.ai.mapHasGeothermal))
	if not tskqbhvr.ai.mapHasGeothermal or tskqbhvr.ai.Energy.income < 150 or tskqbhvr.ai.Metal.income < 10 then
		return DummyUnitName
	end
	if MyTB.side == CORESideName then
		return "corgeo"
	else
		return "armgeo"
	end
end

function BuildMohoGeo(tskqbhvr)
	tskqbhvr:EchoDebug("BuildMohoGeo " .. tostring(tskqbhvr.ai.mapHasGeothermal))
	-- don't attempt if there are no spots on the map
	if not tskqbhvr.ai.mapHasGeothermal or tskqbhvr.ai.Energy.income < 900 or tskqbhvr.ai.Metal.income < 24 then
		return DummyUnitName
	end
	if MyTB.side == CORESideName then
		return "cmgeo"
	else
		return "amgeo"
	end
	-- will turn into a safe geothermal or a geothermal plasma battery if too close to a factory
end

local function BuildSpecialGeo(tskqbhvr)
	-- don't attempt if there are no spots on the map
	if not tskqbhvr.ai.mapHasGeothermal then
		return DummyUnitName
	end
	if MyTB.side == CORESideName then
		return "corbhmt"
	else
		return "armgmm"
	end
end

local function BuildFusion(tskqbhvr)
	if MyTB.side == CORESideName then
		return "corfus"
	else
		return "armfus"
	end
	-- will become cafus and aafus in CategoryEconFilter in TaskQueueBehaviour if energy income is higher than 4000
end

local function BuildAdvFusion(tskqbhvr)
	if MyTB.side == CORESideName then
		return "cafus"
	else
		return "aafus"
	end
	-- will become cafus and aafus in CategoryEconFilter in TaskQueueBehaviour if energy income is higher than 4000
end

local function BuildAdvEnergy(tskqbhvr)
	tskqbhvr:EchoDebug(tostring('advname '..tskqbhvr.name))
	local unitName = DummyUnitName
	unitName = BuildFusion()
	if tskqbhvr.ai.Energy.income > 4000 and (tskqbhvr.name == 'armacv' or tskqbhvr.name == 'coracv') then
		unitName = BuildAdvFusion()
	end
	return unitName
end
			

local function BuildUWFusion(tskqbhvr)
	if MyTB.side == CORESideName then
		return "coruwfus"
	else
		return "armuwfus"
	end
end

function buildEstore1(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corestor"
	else
		unitName = "armestor"
	end
	return unitName
end

function buildEstore2(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "coruwadves"
	else
		unitName = "armuwadves"
	end
	return unitName	
end

function buildMstore1(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
			unitName = "cormstor"
	else
			unitName = "armmstor"
	end
	return unitName
end

function buildMstore2(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "coruwadvms"
	else
		unitName = "armuwadvms"
	end
	return unitName
end

function buildMconv1(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cormakr"	
	else
		unitName = "armmakr"
	end
	return unitName
end

function buildMconv2(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
			unitName ='cormmkr'
	else
			unitName ='armmmkr'
	end
	return unitName
end

function buildMconv2UW(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
			unitName ='corfmmm'
	else
			unitName ='armfmmm'
	end
	return unitName
end

function buildWEstore1(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "coruwes"
	else
		unitName = "armuwes"
	end
	return unitName
end

function buildWMstore1(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "coruwms"
	else
		unitName = "armuwms"
	end
	return unitName
end

function buildWMconv1(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corfmkr"	
	else
		unitName = "armfmkr"
	end
	return unitName
end

function Economy0(tskqbhvr)
	local unitName=DummyUnitName
	if tskqbhvr.ai.Energy.full > 0.1 and (tskqbhvr.ai.Metal.income < 1 or tskqbhvr.ai.Metal.full < 0.3) then
		unitName = BuildMex(tskqbhvr)
	elseif tskqbhvr.ai.Energy.full > 0.9 and tskqbhvr.ai.Energy.income > 400  and tskqbhvr.ai.Metal.reserves > 100 and tskqbhvr.ai.Energy.capacity < 7000 then
		 unitName = buildEstore1(tskqbhvr)
	elseif tskqbhvr.ai.Metal.full > 0.7 and tskqbhvr.ai.Metal.income > 50 and tskqbhvr.ai.Metal.capacity < 4000 and tskqbhvr.ai.Energy.reserves > 500  then
		 unitName = buildMstore1(tskqbhvr)
	elseif tskqbhvr.ai.Energy.income > tskqbhvr.ai.Energy.usage * 1.1 and tskqbhvr.ai.Energy.full > 0.9 and tskqbhvr.ai.Energy.income > 200 and tskqbhvr.ai.Energy.income < 2000 and tskqbhvr.ai.Metal.full < 0.3 then
		unitName = buildMconv1(tskqbhvr)
	elseif (tskqbhvr.ai.Energy.full < 0.5 or tskqbhvr.ai.Energy.income < tskqbhvr.ai.Energy.usage )   then
		unitName = WindSolar(tskqbhvr)
	else
		unitName = BuildMex(tskqbhvr)
	end
	tskqbhvr:EchoDebug('Economy commander '..unitName)
	return unitName
end

function Economy1(tskqbhvr)
        local unitName=DummyUnitName
	if tskqbhvr.ai.Energy.full > 0.5 and tskqbhvr.ai.Metal.full > 0.3 and tskqbhvr.ai.Metal.full < 0.7 and tskqbhvr.ai.Metal.income > 30 then
		unitName = SpecialMex(tskqbhvr)
	elseif (tskqbhvr.ai.Energy.full > 0.5  and tskqbhvr.ai.Metal.full > 0.3 and tskqbhvr.ai.Metal.income > 10 and tskqbhvr.ai.Energy.income > 100) then
		unitName = NanoTurret(tskqbhvr)
	elseif 	tskqbhvr.ai.Energy.full > 0.8 and tskqbhvr.ai.Energy.income > 600 and tskqbhvr.ai.Metal.reserves > 200 and tskqbhvr.ai.Energy.capacity < 7000 then
		unitName = buildEstore1(tskqbhvr)
	elseif tskqbhvr.ai.Metal.full > 0.8 and tskqbhvr.ai.Metal.income > 40 and tskqbhvr.ai.Metal.capacity < 4000  and tskqbhvr.ai.Energy.reserves > 300 then
		unitName = buildMstore1(tskqbhvr)
	elseif tskqbhvr.ai.Energy.income > tskqbhvr.ai.Energy.usage and tskqbhvr.ai.Energy.full > 0.9 and tskqbhvr.ai.Energy.income > 200 and tskqbhvr.ai.Energy.income < 2000 and tskqbhvr.ai.Metal.full < 0.3 then
		unitName = buildMconv1(tskqbhvr)
	elseif (tskqbhvr.ai.Energy.full < 0.3 or tskqbhvr.ai.Energy.income < tskqbhvr.ai.Energy.usage * 1.25) and tskqbhvr.ai.Metal.full > 0.1 then
		unitName = Energy1(tskqbhvr)
	else
		unitName = BuildMex(tskqbhvr)
	end
	tskqbhvr:EchoDebug('Economy level 1 '..unitName)
	return unitName
end

function EconomyUnderWater(tskqbhvr)
	local unitName = DummyUnitName
	if tskqbhvr.ai.Energy.full > 0.9 and tskqbhvr.ai.Energy.income > 500  and tskqbhvr.ai.Metal.reserves > 300 and tskqbhvr.ai.Energy.capacity < 7000 then
		unitName = buildWEstore1(tskqbhvr)
	elseif tskqbhvr.ai.Metal.full > 0.7 and tskqbhvr.ai.Metal.income > 30 and tskqbhvr.ai.Metal.capacity < 4000 and tskqbhvr.ai.Energy.reserves > 600 then
		unitName = buildWMstore1(tskqbhvr)
	elseif tskqbhvr.ai.Energy.income > tskqbhvr.ai.Energy.usage and tskqbhvr.ai.Energy.full > 0.9 and tskqbhvr.ai.Energy.income > 200 and tskqbhvr.ai.Energy.income < 2000 and tskqbhvr.ai.Metal.full < 0.3 then
		unitName = buildWMconv1(tskqbhvr)
	elseif tskqbhvr.ai.Energy.full > 0.1 and (tskqbhvr.ai.Metal.income < 1 or tskqbhvr.ai.Metal.full < 0.6) then
		unitName = BuildUWMex(tskqbhvr)
	elseif (tskqbhvr.ai.Energy.full < 0.3 or tskqbhvr.ai.Energy.income < tskqbhvr.ai.Energy.usage * 1.25) and tskqbhvr.ai.Metal.income > 3 and tskqbhvr.ai.Metal.full > 0.1 then
		unitName = TidalIfTidal(tskqbhvr)--this can get problems
	else
		unitName = BuildUWMex(tskqbhvr)
	end
	tskqbhvr:EchoDebug('Under water Economy level 1 '..unitName)
	return unitName
end

function AdvEconomy(tskqbhvr)
	local unitName=DummyUnitName
	if tskqbhvr.ai.Energy.full > 0.9 and tskqbhvr.ai.Energy.income > 3000 and tskqbhvr.ai.Metal.reserves > 1000 and tskqbhvr.ai.Energy.capacity < 40000 then
		unitName = buildEstore2(tskqbhvr)
	elseif tskqbhvr.ai.Metal.full > 0.8 and tskqbhvr.ai.Metal.income > 100 and tskqbhvr.ai.Metal.capacity < 20000 and tskqbhvr.ai.Energy.full > 0.3 then
		unitName = buildMstore2(tskqbhvr)
	elseif tskqbhvr.ai.Energy.income > tskqbhvr.ai.Energy.usage and tskqbhvr.ai.Energy.full > 0.9 and tskqbhvr.ai.Energy.income > 2000 and tskqbhvr.ai.Metal.full < 0.3 then
		unitName = buildMconv2(tskqbhvr)
	elseif (tskqbhvr.ai.Energy.full < 0.3 or tskqbhvr.ai.Energy.income < tskqbhvr.ai.Energy.usage * 1.25) and tskqbhvr.ai.Metal.full > 0.1 and tskqbhvr.ai.Metal.income > 18 then
		unitName = BuildAdvEnergy(tskqbhvr)
	else--if tskqbhvr.ai.Metal.full < 0.2 and tskqbhvr.ai.Energy.full > 0.1 then
		unitName = BuildMohoMex(tskqbhvr)
	end
	tskqbhvr:EchoDebug('Economy level 3 '..unitName)
	return unitName
end

function AdvEconomyUnderWater(tskqbhvr)
	local unitName = DummyUnitName
	if 	tskqbhvr.ai.Energy.full>0.8 and tskqbhvr.ai.Energy.income > 2500 and tskqbhvr.ai.Metal.reserves > 800 and tskqbhvr.ai.Energy.capacity < 50000  then
		unitName=buildEstore2(tskqbhvr)
	elseif tskqbhvr.ai.Metal.full>0.7 and tskqbhvr.ai.Metal.income>30 and tskqbhvr.ai.Metal.capacity < 20000 and tskqbhvr.ai.Energy.full > 0.4 then
		unitName=buildMstore2(tskqbhvr)
	elseif tskqbhvr.ai.Energy.income > tskqbhvr.ai.Energy.usage and tskqbhvr.ai.Energy.full > 0.9 and tskqbhvr.ai.Energy.income > 2000 and tskqbhvr.ai.Metal.full < 0.3 then
		unitName = buildMconv2UW(tskqbhvr)
	elseif (tskqbhvr.ai.Energy.full<0.3 or tskqbhvr.ai.Energy.income < tskqbhvr.ai.Energy.usage * 1.5) and tskqbhvr.ai.Metal.full>0.1 then
		unitName = BuildUWFusion(tskqbhvr)
	else
		unitName = BuildUWMohoMex(tskqbhvr)
	end
	tskqbhvr:EchoDebug('Economy under water level 2 '..unitName)
	return unitName
end

function EconomySeaplane(tskqbhvr)
	local unitName=DummyUnitName
	if 	tskqbhvr.ai.Energy.full>0.7 and tskqbhvr.ai.Energy.income > 2000 and tskqbhvr.ai.Metal.income>tskqbhvr.ai.Metal.usage and tskqbhvr.ai.Energy.capacity < 60000  then
		unitName=buildEstore2(tskqbhvr)
	elseif tskqbhvr.ai.Metal.full>0.9 and tskqbhvr.ai.Metal.income>30 and tskqbhvr.ai.Metal.capacity < 30000 and tskqbhvr.ai.Energy.full > 0.3 then
		unitName=buildMstore2(tskqbhvr)
	elseif tskqbhvr.ai.Energy.full>0.8  then
		unitName=buildMconv2UW(tskqbhvr)
	elseif tskqbhvr.ai.Energy.full>0.5 and tskqbhvr.ai.Metal.full>0.5 then
		unitName=Lvl2ShipAssist(tskqbhvr) 
	end
	tskqbhvr:EchoDebug('Economy Seaplane '..unitName)
	return unitName
end

function EconomyBattleEngineer(tskqbhvr)
        local unitName=DummyUnitName
	if tskqbhvr.ai.realEnergy > 1.25 and tskqbhvr.ai.realMetal > 1.1 then
		unitName= NanoTurret(tskqbhvr)
	elseif tskqbhvr.ai.Energy.full < 0.1 and tskqbhvr.ai.Metal.full > 0.1 then
		unitName = Solar(tskqbhvr)
	elseif tskqbhvr.ai.Metal.full < 0.2 then 
		unitName=BuildMex(tskqbhvr)
	else
		unitName = EngineerAsFactory(tskqbhvr)
	end
	tskqbhvr:EchoDebug('Economy battle engineer  '..unitName)
	return unitName
end

function EconomyNavalEngineer(tskqbhvr)
        local unitName=DummyUnitName
	if tskqbhvr.ai.Energy.full < 0.2 and realMetal > 1 then
		unitName = TidalIfTidal(tskqbhvr)
	elseif tskqbhvr.ai.Metal.full < 0.2 and tskqbhvr.ai.Energy.income > tskqbhvr.ai.Metal.usage then
		unitName = BuildUWMex(tskqbhvr)
	else
		unitName = NavalEngineerAsFactory(tskqbhvr)
	end
	tskqbhvr:EchoDebug('Economy Naval Engineer '..unitName)
	return unitName
end

function EconomyFark(tskqbhvr)
	local unitName = DummyUnitName
	if (tskqbhvr.ai.Energy.full < 0.3 or tskqbhvr.ai.realEnergy < 1.1)   then
		unitName = WindSolar(tskqbhvr)
	elseif tskqbhvr.ai.Energy.full > 0.9 and tskqbhvr.ai.Metal.capacity < 4000 then
		unitName = buildEstore1(tskqbhvr)
	else
		unitName = BuildMex(tskqbhvr)
	end
	return unitName
end