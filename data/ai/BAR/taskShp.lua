local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("taskShp: " .. inStr)
	end
end
--LEVEL 1

function ConShip()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corcs", ConUnitPerTypeLimit)
	else
		return BuildWithLimitedNumber("armcs", ConUnitPerTypeLimit)
	end
end

function RezSub1(self)
	local unitName
	if ai.mySide == CORESideName then
		unitName = "correcl"
	else
		unitName = "armrecl"
	end
	return BuildWithLimitedNumber(unitName, 1)
end

function Lvl1ShipRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsub"
	else
		unitName = "armsub"
	end
	return BuildRaiderIfNeeded(unitName)
end

function Lvl1ShipDestroyerOnly(self)
	if ai.combatCount > 12 then
		if ai.mySide == CORESideName then
			unitName = "corroy"
		else
			unitName = "armroy"
		end
		return BuildBattleIfNeeded(unitName)
	end
end

function Lvl1ShipBattle(self)
	local unitName = ""
	local r = 1
	if mf>0.8 then r = 2 end -- only build destroyers if you've already got quite a few units (combat = scouts + raiders + battle)
	if r == 1 then
		if ai.mySide == CORESideName then
			unitName = "coresupp"
		else
			unitName = "decade"
		end
	else
		if ai.mySide == CORESideName then
			unitName = "corroy"
		else
			unitName = "armroy"
		end
	end
	return BuildBattleIfNeeded(unitName)
end

function ScoutShip()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corpt"
	else
		unitName = "armpt"
	end
	local scout = BuildWithLimitedNumber(unitName, 1)
	if scout == DummyUnitName then
		return BuildAAIfNeeded(unitName)
	else
		return unitName
	end
end

--LEVEL 2
function ConAdvSub()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("coracsub", ConUnitAdvPerTypeLimit)
	else
		return BuildWithLimitedNumber("armacsub", ConUnitAdvPerTypeLimit)
	end
end

function Lvl2ShipAssist()
	if ai.mySide == CORESideName then
		return "cormls"
	else
		return "armmls"
	end
end

function Lvl2ShipBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corbats"
	else
		unitName = "armbats"
	end
	return BuildBreakthroughIfNeeded(unitName)
end

function Lvl2ShipMerl(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cormship"
	else
		unitName = "armmship"
	end
	return BuildSiegeIfNeeded(unitName)
end

function MegaShip()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corblackhy"
	else
		unitName = "aseadragon"
	end
	return BuildBreakthroughIfNeeded(BuildWithLimitedNumber(unitName, 1))
end

function Lvl2ShipRaider(self)
	local unitName = ""
		if ai.mySide == CORESideName then
			unitName = "corshark"
		else
			unitName = "armsubk"
		end

	return BuildRaiderIfNeeded(unitName)
end

function Lvl2SubLight(self)
	local unitName = ""
		if ai.mySide == CORESideName then
			unitName = "corssub"
		else
			unitName = "tawf009"
		end

	return BuildRaiderIfNeeded(unitName)
end

function Lvl2ShipBattle(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corcrus"
	else
		unitName = "armcrus"
	end
	return BuildBattleIfNeeded(unitName)
end

function Lvl2AAShip()
	if ai.mySide == CORESideName then
		return BuildAAIfNeeded("corarch")
	else
		return BuildAAIfNeeded("armaas")
	end
end

