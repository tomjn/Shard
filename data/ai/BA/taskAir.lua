--LEVEL 1

function ConAir(tskqbhvr)
	unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corca"
	else
		unitName = "armca"
	end
	local mtypedLv = GetMtypedLv(tskqbhvr, unitName)
	return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 6) + 1, tskqbhvr.ai.conUnitPerTypeLimit))
end

function Lvl1AirRaider(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "bladew"
	else
		unitName = "armkam"
	end
	return BuildRaiderIfNeeded(tskqbhvr, unitName)
end

function Lvl1Fighter(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corveng"
	else
		unitName = "armfig"
	end
	return BuildAAIfNeeded(tskqbhvr, unitName)
end

function Lvl1Bomber(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corshad"
	else
		unitName = "armthund"
	end
	return BuildBomberIfNeeded(tskqbhvr, unitName)
end

function ScoutAir(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corfink"
	else
		unitName = "armpeep"
	end
	return BuildWithLimitedNumber(tskqbhvr, unitName, 1)
end

--LEVEL 2
function ConAdvAir(tskqbhvr)
	unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "coraca"
	else
		unitName = "armaca"
	end
	local mtypedLv = GetMtypedLv(tskqbhvr, unitName)
	return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 8) + 1, tskqbhvr.ai.conUnitAdvPerTypeLimit))
end

function Lvl2Fighter(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corvamp"
	else
		unitName = "armhawk"
	end
	return BuildAAIfNeeded(tskqbhvr, unitName)
end

function Lvl2AirRaider(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "corape"
	else
		-- spedical case: arm has an ubergunship
		local raidCounter = tskqbhvr.ai.raidhandler:GetCounter("air")
		if raidCounter < baseRaidCounter and raidCounter > minRaidCounter then
			return "blade"
		else
			unitName = "armbrawl"
		end
	end
	return BuildRaiderIfNeeded(tskqbhvr, unitName)
end

function Lvl2Bomber(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corhurc"
	else
		unitName = "armpnix"
	end
	return BuildBomberIfNeeded(tskqbhvr, unitName)
end


function Lvl2TorpedoBomber(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "cortitan"
	else
		unitName = "armlance"
	end
	return BuildTorpedoBomberIfNeeded(tskqbhvr, unitName)
end

function MegaAircraft(tskqbhvr)
	if MyTB.side == CORESideName then
		return BuildBreakthroughIfNeeded(tskqbhvr, "corcrw")
	else
		return BuildBreakthroughIfNeeded(tskqbhvr, "armcybr")
	end
end


function ScoutAdvAir(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corawac"
	else
		unitName = "armawac"
	end
	return BuildWithLimitedNumber(tskqbhvr, unitName, 1)
end

--SEAPLANE
function ConSeaAir(tskqbhvr)
	unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corcsa"
	else
		unitName = "armcsa"
	end
	local mtypedLv = GetMtypedLv(tskqbhvr, unitName)
	return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 9) + 1, tskqbhvr.ai.conUnitAdvPerTypeLimit))
end

function SeaBomber(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corsb"
	else
		unitName = "armsb"
	end
	return BuildBomberIfNeeded(tskqbhvr, unitName)
end

function SeaTorpedoBomber(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corseap"
	else
		unitName = "armseap"
	end
	return BuildTorpedoBomberIfNeeded(tskqbhvr, unitName)
end

function SeaFighter(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corsfig"
	else
		unitName = "armsfig"
	end
	return BuildAAIfNeeded(tskqbhvr, unitName)
end

function SeaAirRaider(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "corcut"
	else
		unitName = "armsaber"
	end
	return BuildRaiderIfNeeded(tskqbhvr, unitName)
end

function ScoutSeaAir(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corhunt"
	else
		unitName = "armsehak"
	end
	return BuildWithLimitedNumber(tskqbhvr, unitName, 1)
end

--AIRPAD
function AirRepairPadIfNeeded(tskqbhvr)
	local tmpUnitName = DummyUnitName

	-- only make air pads if the team has at least 1 air fac
	if CountOwnUnits(tskqbhvr, "corap") > 0 or CountOwnUnits(tskqbhvr, "armap") > 0 or CountOwnUnits(tskqbhvr, "coraap") > 0 or CountOwnUnits(tskqbhvr, "armaap") > 0 then
		if MyTB.side == CORESideName then
			tmpUnitName = "corasp"
		else
			tmpUnitName = "armasp"
		end
	end
	
	return BuildWithLimitedNumber(tskqbhvr, tmpUnitName, tskqbhvr.ai.conUnitPerTypeLimit)
end
