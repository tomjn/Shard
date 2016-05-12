

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("taskBot: " .. inStr)
	end
end


--LEVEL 1

function ConBot()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corck", ConUnitPerTypeLimit)
	else
		return BuildWithLimitedNumber("armck", ConUnitPerTypeLimit)
	end
end

function RezBot1(self)
	local unitName
	if ai.mySide == CORESideName then
		unitName = "cornecro"
	else
		unitName = "armrectr"
	end
	return BuildWithLimitedNumber(unitName, 1)
end

function Lvl1BotRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corak"
	else
		unitName = "armpw"
	end
	return BuildRaiderIfNeeded(unitName)
end

function Lvl1BotBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corthud"
	else
		unitName = "armwar"
	end
	return BuildBreakthroughIfNeeded(unitName)
end

function Lvl1BotBattle(self)
	local unitName = ""
	local r = math.random(1, 2)
	if r == 1 then
		if ai.mySide == CORESideName then
			unitName = "corthud"
		else
			unitName = "armham"
		end
	else
		if ai.mySide == CORESideName then
			unitName = "corstorm"
		else
			unitName = "armrock"
		end
	end
	return BuildBattleIfNeeded(unitName)
end

function Lvl1AABot()
	if ai.mySide == CORESideName then
		return BuildAAIfNeeded("corcrash")
	else
		return BuildAAIfNeeded("armjeth")
	end
end

function ScoutBot()
	local unitName
	if ai.mySide == CORESideName then
		return DummyUnitName
	else
		unitName = "armflea"
	end
	return BuildWithLimitedNumber(unitName, 1)
end

--LEVEL 2

function ConAdvBot()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corack", ConUnitAdvPerTypeLimit)
	else
		return BuildWithLimitedNumber("armack", ConUnitAdvPerTypeLimit)
	end
end


function Lvl2BotAssist()
	if ai.mySide == CORESideName then
		return "corfast"
	else
		return "armfark"
	end
end

function NewCommanders(self)
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = 'commando'
	else
		unitName = DummyUnitName
	end
	return unitName
end
	
function Decoy(self)
	local unitName = DummyUnitName
	if ai.mySide == CORESideName then
		unitName = 'cordecom'
	else
		unitName = 'armdecom'
	end
	return unitName
end


function Lvl2BotBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsumo"
	else
		unitName = "armfboy"
	end
	return BuildBreakthroughIfNeeded(unitName)
end

function Lvl2BotArty(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cormort"
	else
		unitName = "armfido"
	end
	return BuildSiegeIfNeeded(unitName)
end

function Lvl2BotLongRange(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corhrk"
	else
		unitName = "armsnipe"
	end
	return BuildSiegeIfNeeded(unitName)
end

function Lvl2BotRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corpyro"
	else
		unitName = "armfast"
	end
	return BuildRaiderIfNeeded(unitName)
end

function Lv2BotAllTerrain(self)
	local unitName=DummyUnitName
	if ai.mySide == CORESideName then
		unitName = 'cortermite'
	else
		unitName = "armsptk"
	end
	return unitName
end

function Lvl2BotBattle(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corcan"
	else
		unitName = "armzeus"
	end
	return BuildBattleIfNeeded(unitName)
end

function Lv2BotMedium(self)
	local unitName=DummyUnitName
	if ai.mySide == CORESideName then
		unitName = 'corcan'
	else
		unitName = "armmav"
	end
end

function Lv2AmphBot(self)
	local unitName=DummyUnitName
	if ai.mySide == CORESideName then
		unitName = 'coramph'
	else
		unitName = 'armamph'
	end
end

function Lvl2AABot()
	if ai.mySide == CORESideName then
		return BuildAAIfNeeded("coraak")
	else
		return BuildAAIfNeeded("armaak")
	end
end
