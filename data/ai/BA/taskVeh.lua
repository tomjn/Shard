--LEVEL 1

function ConVehicleAmphibious(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cormuskrat"
	else
		unitName = "armbeaver"
	end
	local mtypedLvAmph = GetMtypedLv(tskqbhvr, unitName)
	local mtypedLvGround = GetMtypedLv(tskqbhvr, 'armcv')
	local mtypedLv = math.max(mtypedLvAmph, mtypedLvGround) --workaround for get the best counter
	return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 6) + 1, tskqbhvr.ai.conUnitPerTypeLimit))
end

function ConGroundVehicle(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corcv"
	else
		unitName = "armcv"
	end
	local mtypedLv = GetMtypedLv(tskqbhvr, unitName)
	return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 6) + 1, tskqbhvr.ai.conUnitPerTypeLimit))
end

function ConVehicle(tskqbhvr)
	local unitName = DummyUnitName
	-- local amphRank = (((tskqbhvr.ai.mobCount['shp']) / tskqbhvr.ai.mobilityGridArea ) +  ((#tskqbhvr.ai.UWMetalSpots) /(#tskqbhvr.ai.landMetalSpots + #tskqbhvr.ai.UWMetalSpots)))/ 2
	local amphRank = MyTB.amphRank or 0.5
	if math.random() < amphRank then
		unitName = ConVehicleAmphibious(tskqbhvr)
	else
		unitName = ConGroundVehicle(tskqbhvr)
	end
	return unitName
end

function Lvl1VehBreakthrough(tskqbhvr)
	if tskqbhvr.AmpOrGroundWeapon then
		return Lvl1Amphibious(tskqbhvr)
	else
		if MyTB.side == CORESideName then
			return BuildBreakthroughIfNeeded(tskqbhvr, "corlevlr")
		else
			-- armjanus isn't very a very good defense unit by itself
			local output = BuildSiegeIfNeeded(tskqbhvr, "armjanus")
			if output == DummyUnitName then
				output = BuildBreakthroughIfNeeded(tskqbhvr, "armstump")
			end
			return output
		end
	end
end

function Lvl1VehArty(tskqbhvr)
	local unitName = DummyUnitName
	if tskqbhvr.AmpOrGroundWeapon then
		return Lvl1Amphibious(tskqbhvr)
	else
		if MyTB.side == CORESideName then
			unitName = "corwolv"
		else
			unitName = "tawf013"
		end
	end
	return BuildSiegeIfNeeded(tskqbhvr, unitName)
end

function AmphibiousRaider(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "corgarp"
	else
		unitName = "armpincer"
	end
	return BuildRaiderIfNeeded(tskqbhvr, unitName)
end

function Lvl1Amphibious(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "corgarp"
	else
		unitName = "armpincer"
	end
	return unitName
end

function Lvl1VehRaider(tskqbhvr)
	local unitName = DummyUnitName
	if tskqbhvr.AmpOrGroundWeapon then
		return Lvl1Amphibious(tskqbhvr)
	else
		if MyTB.side == CORESideName then
			unitName = "corgator"
		else
			unitName = "armflash"
		end
	end
	return BuildRaiderIfNeeded(tskqbhvr, unitName)
end

function Lvl1VehBattle(tskqbhvr)
	local unitName = DummyUnitName
	if tskqbhvr.AmpOrGroundWeapon then
		return Lvl1Amphibious(tskqbhvr)
	else
		if MyTB.side == CORESideName then
			unitName = "corraid"
		else
			unitName = "armstump"
		end
	end
	return BuildBattleIfNeeded(tskqbhvr, unitName)
end

function Lvl1VehRaiderOutmoded(tskqbhvr)
	if tskqbhvr.AmpOrGroundWeapon then
		return Lvl1Amphibious(tskqbhvr)
	else
		if MyTB.side == CORESideName then
			return BuildRaiderIfNeeded(tskqbhvr, "corgator")
		else
			return DummyUnitName
		end
	end
end

function Lvl1AAVeh(tskqbhvr)
	if MyTB.side == CORESideName then
		return BuildAAIfNeeded(tskqbhvr, "cormist")
	else
		return BuildAAIfNeeded(tskqbhvr, "armsam")
	end
end

function ScoutVeh(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corfav"
	else
		unitName = "armfav"
	end
	return BuildWithLimitedNumber(tskqbhvr, unitName, 1)
end

--LEVEL 2

function ConAdvVehicle(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "coracv"
	else
		unitName = "armacv"
	end
	local mtypedLv = GetMtypedLv(tskqbhvr, unitName)
	return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 10) + 1, tskqbhvr.ai.conUnitAdvPerTypeLimit))
end

function Lvl2VehAssist(tskqbhvr)
	if MyTB.side == CORESideName then
		return DummyUnitName
	else
		unitName = 'consul'
		local mtypedLv = GetMtypedLv(tskqbhvr, unitName)
		return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 8) + 1, tskqbhvr.ai.conUnitPerTypeLimit))
	end
end

function Lvl2VehBreakthrough(tskqbhvr)
	local unitName = DummyUnitName
	if tskqbhvr.AmpOrGroundWeapon then
		return Lvl2Amphibious(tskqbhvr)
	else
		if MyTB.side == CORESideName then
			return BuildBreakthroughIfNeeded(tskqbhvr, "corgol")
		else
			-- armmanni isn't very a very good defense unit by itself
			local output = BuildSiegeIfNeeded(tskqbhvr, "armmanni")
			if output == DummyUnitName then
				output = BuildBreakthroughIfNeeded(tskqbhvr, "armbull")
			end
			return output
		end
	end
end

function Lvl2VehArty(tskqbhvr)
	local unitName = DummyUnitName
	if tskqbhvr.AmpOrGroundWeapon then
		return Lvl2Amphibious(tskqbhvr)
	else
		if MyTB.side == CORESideName then
			unitName = "cormart"
		else
			unitName = "armmart"
		end
	end
	return BuildSiegeIfNeeded(tskqbhvr, unitName)
end

-- because core doesn't have a lvl2 vehicle raider or a lvl3 raider


function Lvl2VehRaider(tskqbhvr)
	local unitName = DummyUnitName
	if tskqbhvr.AmpOrGroundWeapon then
		return Lvl2Amphibious(tskqbhvr)
	else
		if MyTB.side == CORESideName then
			unitName = ("corseal")
		else
			unitName = ("armlatnk")
		end
	end
	return BuildRaiderIfNeeded(tskqbhvr, unitName)
end



function AmphibiousBattle(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		if tskqbhvr.ai.Metal.full < 0.5 then	
			unitName = "corseal" 
		else
			unitName = "corparrow" 
		end
			
	else
		unitName = "armcroc"
	end
	return BuildBattleIfNeeded(tskqbhvr, unitName)
end

function Lvl2Amphibious(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		if tskqbhvr.ai.Metal.full < 0.5 then	
			unitName = "corseal" 
		else
			unitName = "corparrow" 
		end
			
	else
		unitName = "armcroc"
	end
	return unitName
end

function AmphibiousBreakthrough(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corparrow"
	else
		unitName = "armcroc"
	end
	return BuildBreakthroughIfNeeded(tskqbhvr, unitName)
end

function Lvl2VehBattle(tskqbhvr)
	local unitName = DummyUnitName
	if tskqbhvr.AmpOrGroundWeapon then
		return Lvl2Amphibious(tskqbhvr)
	else
		if MyTB.side == CORESideName then
			unitName = "correap"
		else
			unitName = "armbull"
		end
	end
	return BuildBattleIfNeeded(tskqbhvr, unitName)
end

function Lvl2AAVeh(tskqbhvr)
	if MyTB.side == CORESideName then
		return BuildAAIfNeeded(tskqbhvr, "corsent")
	else
		return BuildAAIfNeeded(tskqbhvr, "armyork")
	end
end

function Lvl2VehMerl(tskqbhvr)
	local unitName = DummyUnitName
	if tskqbhvr.AmpOrGroundWeapon then
		return Lvl2Amphibious(tskqbhvr)
	else
		if MyTB.side == CORESideName then
			unitName = "corvroc"
		else
			unitName = "armmerl"
		end
	end
	return BuildSiegeIfNeeded(tskqbhvr, unitName)
end




