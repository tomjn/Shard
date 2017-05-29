--SOME FUNCTIONS ARE DUPLICATE HERE
function Lvl3Merl(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "armraven"
	else
		unitName = DummyUnitName
	end
	return BuildSiegeIfNeeded(tskqbhvr, unitName)
end

function Lvl3Arty(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "shiva"
	else
		unitName = "armshock"
	end
	return BuildSiegeIfNeeded(tskqbhvr, unitName)
end

function lv3Amp(tskqbhvr)
	local unitName=DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "shiva"
	else
		unitName = "marauder"
	end
	return BuildSiegeIfNeeded(tskqbhvr, unitName)
end

function Lvl3Breakthrough(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = BuildWithLimitedNumber(tskqbhvr, "corkrog", 1)
		if unitName == DummyUnitName then
			unitName = BuildWithLimitedNumber(tskqbhvr, "gorg", 2)
		end
		if unitName == DummyUnitName then
			unitName = "corkarg"
		end
	else
		unitName = BuildWithLimitedNumber(tskqbhvr, "armbanth", 5)
		if unitName == DummyUnitName then
			unitName = "armraz"
		end
	end
	return BuildBreakthroughIfNeeded(tskqbhvr, unitName)
end

function lv3bigamp(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = 'corkrog'
	else
		unitName = 'armbanth'
	end
	return unitName
end

function Lvl3Raider(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = DummyUnitName
	else
		unitName = "marauder"
	end
	tskqbhvr:EchoDebug(unitName)
	return BuildRaiderIfNeeded(tskqbhvr, unitName)
end

function Lvl3Battle(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "corkarg"
	else
		unitName = "armraz"
	end
	return BuildBattleIfNeeded(tskqbhvr, unitName)
end

function Lvl3Hov(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corsok"
	else
		unitName = "armlun"
	end
	return BuildBattleIfNeeded(tskqbhvr, unitName)
end
	
function Lv3VehAmp(tskqbhvr)
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
	return BuildSiegeIfNeeded(tskqbhvr, unitName)
end
	
	
function Lv3Special(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "gorg"
	else
		unitName = "armshock"
	end
	return BuildBattleIfNeeded(tskqbhvr, unitName)
end
	