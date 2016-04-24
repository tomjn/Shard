
shard_include('common')
local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("taskEco: " .. inStr)
	end
end

--ECONOMIA

function BuildAppropriateFactory()
	if  ei>((ai.factories*ai.factories)*200)+30 and mi>((ai.factories*ai.factories)*20)+3 then
		return FactoryUnitName
	else
		return DummyUnitName
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

function BuildMex0()

	local unitName
	if ai.mySide == CORESideName then
		unitName = "cormex"
	else
		unitName = "armmex"
	end
	return unitName
end

function BuildMex1()
	local unitName
	if mi <10 then
		if ai.mySide == CORESideName then
			unitName = "cormex"
		else
			unitName = "armmex"
		end
	else
		if ai.mySide == CORESideName then
			unitName = "corexp"
		else
			unitName = "armamex"
		end
	end
	return unitName
end

--primo livello acqua
function BuildUWMex()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "coruwmex"
	else
		unitName = "armuwmex"
	end
	return unitName
end

--secondo livello
function BuildMohoMex()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "cormexp"
	else
		unitName = "armmoho"
	end
	return unitName
end


--secondo livello acqua
function BuildUWMohoMex()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "coruwmme"
	else
		unitName = "armuwmme"
	end
	return unitName
end

function TidalIfTidal(self)
	local unitName = DummyUnitName
	if ai.haveAdvFactory and ei>1000 and ef>0.1 then
		return unitName
	end
	EchoDebug("tidal power is " .. tidalPower)
	if tidalPower >= 10 then
		if ai.mySide == CORESideName then
			unitName = "cortide"
		else
			unitName = "armtide"
		end
	end
	return unitName
end

function Energy1(self)
	local unitName=DummyUnitName


	local wind = false
		if needWind then
			if windRatio == 1 then
				wind = true
			else
				local r = math.random()
				if r < windRatio then wind = true end
			end
		end
		if ei>150  then --and mr >50
			if ai.mySide == CORESideName then
				unitName= "coradvsol"
			else
				unitName= "armadvsol"
			end
		elseif wind then
			if ai.mySide == CORESideName then
				unitName="corwin"
			else
				unitName="armwin"
			end
		else
			if ai.mySide == CORESideName then
				unitName="corsolar"
			else
				unitName="armsolar"
			end
		end
	return unitName
end

function WindSolar()
	if ai.haveAdvFactory and ei>1000 and ef>0.1 then
		return DummyUnitName
	end
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
		if ai.mySide == CORESideName then
			return "corwin"
		else
			return "armwin"
		end
	else
		if ai.mySide == CORESideName then
			return "corsolar"
		else
			return "armsolar"
		end
	end
end

function Solar()
	if ai.haveAdvFactory and ei>1000 and ef>0.1 then
		return DummyUnitName
	end
	if ai.mySide == CORESideName then
		return "corsolar"
	else
		return "armsolar"
	end
end

function SolarAdv()
	if ai.mySide == CORESideName then
		return "coradvsol"
	else
		return "armadvsol"
	end
end

function BuildGeo()
	-- don't attempt if there are no spots on the map
	if not ai.mapHasGeothermal then
		return DummyUnitName
	end
	if er>2000 or ei< 300 then return DummyUnitName end
	if ai.mySide == CORESideName then
		return "corgeo"
	else
		return "armgeo"
	end
end

function BuildMohoGeo(self)
	-- don't attempt if there are no spots on the map
	if not ai.mapHasGeothermal then
		return DummyUnitName
	end
	if ai.mySide == CORESideName then
		return "cmgeo"
	else
		return "amgeo"
	end
	-- will turn into a safe geothermal or a geothermal plasma battery if too close to a factory
end

function BuildFusion()
	if ai.mySide == CORESideName then
		return "corfus"
	else
		return "armfus"
	end
	-- will become cafus and aafus in CategoryEconFilter in TaskQueueBehaviour if energy income is higher than 4000
end

function BuildFusion3()
	if ei<2000 then
	
		if ai.mySide == CORESideName then
			return "corfus"
		else
			return "armfus"
		end
	else
		if ai.mySide == CORESideName then
			return "cafus"
		else
			return "aafus"
		end
	end
		-- will become cafus and aafus in CategoryEconFilter in TaskQueueBehaviour if energy income is higher than 4000
end

function BuildUWFusion()
	--print(tostring('fusionh2o'))
	if ai.mySide == CORESideName then
		return "coruwfus"
	else
		return "armuwfus"
	end
end

function buildEstore1(self)
	local unitName = DummyUnitName
	if  not ai.haveAdvFactory then
		
		if ai.mySide == CORESideName then
			if ec < 7000  then
				unitName = "corestor"
			else
				unitName = 'cormakr'
			end
		else
			if ec < 7000 then
				unitName = "armestor"
			else
				unitName = 'armmakr'
			end
		end
	end
	--print(tostring('buildEstore1 ' .. unitName))
	return unitName
end

function buildEstore2(self)
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		if 	ec<60000 then
			unitName = "coruwadves"
		else
			unitName ='corfmmm'
		end
	else
		if ec<60000 then
			unitName = "armuwadves"
		else
			unitName = 'armfmmm'
		end
	end
	--print(tostring('buildEstore2 ' .. unitName))
	return unitName	
end

function buildMstore1(self)
	local unitName = DummyUnitName
	if  not ai.haveAdvFactory or mc < 5000 then
		if ai.mySide == CORESideName then
				unitName = "cormstor"
		else
				unitName = "armmstor"
		end
	end
	return unitName
end

function buildMstore2(self)
	local unitName = DummyUnitName
	if mc < 20000 then
		if ai.mySide == CORESideName then
			--if not have('coruwadvms',2) then
				unitName = "coruwadvms"
			--end
		else
			--if not have('armuwadvms',2) then
				unitName = "armuwadvms"
			--end
		end
	end
	--print(tostring('buildMstore2 ' .. unitName))
	return unitName
end

function buildMconv1(self)
	local unitName = DummyUnitName

		if ai.mySide == CORESideName then
			unitName = "cormakr"	
		else
			unitName = "armmakr"
		end
	--print(tostring('buildMconv1 ' .. unitName))
	return unitName
end

function buildMconv2(self)
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		--if (lnf['coruwadvms'])~=nil and lnf['coruwadvms']>=1 then
			unitName ='cormmkr'
		--end
	else
		--if (lnf['armuwadvms'])~=nil and lnf['armuwadvms']>=1 then
			unitName ='armmmkr'
		--end
	end
	--print(tostring('buildMconv2 ' .. unitName))
	return unitName
end

function buildMconv2UW(self)
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		--if (lnf['coruwadvms'])~=nil and lnf['coruwadvms']>=1 then
			unitName ='corfmmm'
		--end
	else
		--if (lnf['armuwadvms'])~=nil and lnf['armuwadvms']>=1 then
			unitName ='armfmmm'
		--end
	end
	--print(tostring('buildMconv2 ' .. unitName))
	return unitName
end

function buildWEstore1(self)
	local unitName = DummyUnitName
	if  not ai.haveAdvFactory then
		
		if ai.mySide == CORESideName then
			if ec < 8000  then
				unitName = "coruwes"
			else
				unitName = 'corfmkr'
			end
		else
			if ec < 8000 then
				unitName = "armuwes"
			else
				unitName = 'armfmkr'
			end
		end
	end
	--print(tostring('buildEstore1 ' .. unitName))
	return unitName
end

function buildWMstore1(self)
	local unitName = DummyUnitName
	if  not ai.haveAdvFactory or mc < 5000 then
		if ai.mySide == CORESideName then
			unitName = "coruwms"
		else
			unitName = "armuwms"
		end
	end
	--print(tostring('buildMstore1 ' .. unitName))
	return unitName
end

function buildWMconv1(self)
	local unitName = DummyUnitName
	if  not ai.haveAdvFactory then
		if ai.mySide == CORESideName then
			unitName = "corfmkr"	
		else
			unitName = "armfmkr"
		end
	end
	--print(tostring('buildMconv1 ' .. unitName))
	return unitName
end