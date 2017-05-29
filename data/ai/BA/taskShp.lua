--LEVEL 1

function ConShip(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corcs"
	else
		unitName = "armcs"
	end
	local mtypedLv = GetMtypedLv(tskqbhvr, unitName) + GetMtypedLv(tskqbhvr, 'correcl') --need count sub too
	return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 5) + 2, tskqbhvr.ai.conUnitPerTypeLimit))
end

function RezSub1(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "correcl"
	else
		unitName = "armrecl"
	end
	local mtypedLv = GetMtypedLv(tskqbhvr, unitName) + GetMtypedLv(tskqbhvr, 'armcs') --need count shp too
	return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 8) + 2, tskqbhvr.ai.conUnitPerTypeLimit))
end

function Lvl1ShipRaider(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corsub"
	else
		unitName = "armsub"
	end
	return BuildRaiderIfNeeded(tskqbhvr, unitName)
end

function Lvl1ShipDestroyerOnly(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corroy"
	else
		unitName = "armroy"
	end
	local mtypedLv = GetMtypedLv(tskqbhvr, unitName) + GetMtypedLv(tskqbhvr, 'armcs')
	return BuildWithLimitedNumber(tskqbhvr, unitName,mtypedLv * 0.7)
end

function Lvl1ShipBattle(tskqbhvr)
	local unitName = ""
	if tskqbhvr.ai.Metal.full < 0.5 then
		if MyTB.side == CORESideName then
			unitName = "coresupp"
		else
			unitName = "decade"
		end
	else
		if MyTB.side == CORESideName then
			unitName = "corroy"
		else
			unitName = "armroy"
		end
	end
	return BuildBattleIfNeeded(tskqbhvr, unitName)
end

function ScoutShip(tskqbhvr)
	local unitName
	if MyTB.side == CORESideName then
		unitName = "corpt"
	else
		unitName = "armpt"
	end
	local scout = BuildWithLimitedNumber(tskqbhvr, unitName, 1)
	if scout == DummyUnitName then
		return BuildAAIfNeeded(tskqbhvr, unitName)
	else
		return unitName
	end
end

--LEVEL 2
function ConAdvSub(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "coracsub"
	else
		unitName = "armacsub"
	end
	local mtypedLv = GetMtypedLv(tskqbhvr, unitName) + GetMtypedLv(tskqbhvr, 'cormls') --need count shp too
	return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 6) + 2, tskqbhvr.ai.conUnitPerTypeLimit))
end

function Lvl2ShipAssist(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cormls"
	else
		unitName = "armmls"
	end
	local mtypedLv = GetMtypedLv(tskqbhvr, unitName) + GetMtypedLv(tskqbhvr, 'coracsub') --need count sub too
	return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 6) + 2, tskqbhvr.ai.conUnitPerTypeLimit))
end

function Lvl2ShipBreakthrough(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "corbats"
	else
		unitName = "armbats"
	end
	return BuildBreakthroughIfNeeded(tskqbhvr, unitName)
end

function Lvl2ShipMerl(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "cormship"
	else
		unitName = "armmship"
	end
	return BuildSiegeIfNeeded(tskqbhvr, unitName)
end

function MegaShip(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "corblackhy"
	else
		unitName = "aseadragon"
	end
	return BuildBreakthroughIfNeeded(tskqbhvr, BuildWithLimitedNumber(tskqbhvr, unitName, 1))
end

function Lvl2ShipRaider(tskqbhvr)
	local unitName = ""
		if MyTB.side == CORESideName then
			unitName = "corshark"
		else
			unitName = "armsubk"
		end

	return BuildRaiderIfNeeded(tskqbhvr, unitName)
end

function Lvl2SubWar(tskqbhvr)
	local unitName = DummyUnitName
		if MyTB.side == CORESideName then
			unitName = "corssub"
		else
			unitName = "tawf009"
		end

	return BuildBattleIfNeeded(tskqbhvr, unitName)
end

function Lvl2ShipBattle(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "corcrus"
	else
		unitName = "armcrus"
	end
	return BuildBattleIfNeeded(tskqbhvr, unitName)
end

function Lvl2AAShip()
	if MyTB.side == CORESideName then
		return BuildAAIfNeeded(tskqbhvr, "corarch")
	else
		return BuildAAIfNeeded(tskqbhvr, "armaas")
	end
end

