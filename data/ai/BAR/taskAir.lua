
--shard_include('taskqueues')
local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("unitBot: " .. inStr)
	end
end

function ConAir()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corca", ConUnitPerTypeLimit)
	else
		return BuildWithLimitedNumber("armca", ConUnitPerTypeLimit)
	end
end

function ConAdvAir()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("coraca", ConUnitAdvPerTypeLimit)
	else
		return BuildWithLimitedNumber("armaca", ConUnitAdvPerTypeLimit)
	end
end

function ConSeaAir()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corcsa", ConUnitPerTypeLimit)
	else
		return BuildWithLimitedNumber("armcsa", ConUnitPerTypeLimit)
	end
end

function Lvl1AirRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "bladew"
	else
		unitName = "armkam"
	end
	return BuildRaiderIfNeeded(unitName)
end

function MegaAircraft()
	if ai.mySide == CORESideName then
		return BuildBreakthroughIfNeeded("corcrw")
	else
		return BuildBreakthroughIfNeeded("armcybr")
	end
end


function Lvl2AirRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corape"
	else
		-- spedical case: arm has an ubergunship
		local raidCounter = ai.raidhandler:GetCounter("air")
		if raidCounter < baseRaidCounter and raidCounter > minRaidCounter then
			return "blade"
		else
			unitName = "armbrawl"
		end
	end
	return BuildRaiderIfNeeded(unitName)
end

function Lvl1Bomber()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corshad"
	else
		unitName = "armthund"
	end
	return BuildBomberIfNeeded(unitName)
end
function Lvl1AirSupport()
	local unitName=dummyUnitName
	if ef and mf>0.5 then
		if ai.mySide == CORESideName then
			unitName = "corshad"
		else
			unitName = "armthund"
		end
	else
		if ai.mySide == CORESideName then
			unitName = "bladew"
		else
			unitName = "armcam"
		end
	end
	return BuildWithLimitedNumber(unitName,20)
end


function Lvl1Fighter()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corveng"
	else
		unitName = "armfig"
	end
	return BuildAAIfNeeded(unitName)
end

function Lvl2Bomber()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corhurc"
	else
		unitName = "armpnix"
	end
	return BuildBomberIfNeeded(unitName)
end

function Lvl2TorpedoBomber()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "cortitan"
	else
		unitName = "armlance"
	end
	return BuildTorpedoBomberIfNeeded(unitName)
end

function Lvl2Fighter()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corvamp"
	else
		unitName = "armhawk"
	end
	return BuildAAIfNeeded(unitName)
end

function SeaBomber()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corsb"
	else
		unitName = "armsb"
	end
	return BuildBomberIfNeeded(unitName)
end

function SeaTorpedoBomber()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corseap"
	else
		unitName = "armseap"
	end
	return BuildTorpedoBomberIfNeeded(unitName)
end

function SeaFighter()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corsfig"
	else
		unitName = "armsfig"
	end
	return BuildAAIfNeeded(unitName)
end

function SeaAirRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corcut"
	else
		unitName = "armsaber"
	end
	return BuildRaiderIfNeeded(unitName)
end

function ScoutAir()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corfink"
	else
		unitName = "armpeep"
	end
	return BuildWithLimitedNumber(unitName, 1)
end


function ScoutAdvAir()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corawac"
	else
		unitName = "armawac"
	end
	return BuildWithLimitedNumber(unitName, 1)
end

function ScoutSeaAir()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corhunt"
	else
		unitName = "armsehak"
	end
	return BuildWithLimitedNumber(unitName, 1)
end

function AirRepairPadIfNeeded()
	local tmpUnitName = DummyUnitName

	-- only make air pads if the team has at least 1 air fac
	if CountOwnUnits("corap") > 0 or CountOwnUnits("armap") > 0 or CountOwnUnits("coraap") > 0 or CountOwnUnits("armaap") > 0 then
		if ai.mySide == CORESideName then
			tmpUnitName = "corasp"
		else
			tmpUnitName = "armasp"
		end
	end
	
	return BuildWithLimitedNumber(tmpUnitName, ConUnitPerTypeLimit)
end