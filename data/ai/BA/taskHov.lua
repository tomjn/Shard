function ConHover(tskqbhvr)
	if MyTB.side == CORESideName then
		unitName = "corch"
	else
		unitName = "armch"
	end
	local mtypedLv = GetMtypedLv(tskqbhvr, unitName)
	return BuildWithLimitedNumber(tskqbhvr, unitName, math.min((mtypedLv / 6) + 1, tskqbhvr.ai.conUnitPerTypeLimit))
end

function HoverMerl(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "cormh"
	else
		unitName = "armmh"
	end
	return BuildSiegeIfNeeded(tskqbhvr, unitName)
end

function HoverRaider(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "corsh"
	else
		unitName = "armsh"
	end
	return BuildRaiderIfNeeded(tskqbhvr, unitName)
end

function HoverBattle(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "corsnap"
	else
		unitName = "armanac"
	end
	return BuildBattleIfNeeded(tskqbhvr, unitName)
end

function HoverBreakthrough(tskqbhvr)
	local unitName = ""
	if MyTB.side == CORESideName then
		unitName = "nsaclash"
	else
		unitName = "armanac"
	end
	BuildBreakthroughIfNeeded(tskqbhvr, unitName)
end

function AAHover(tskqbhvr)
	if MyTB.side == CORESideName then
		return BuildAAIfNeeded(tskqbhvr, "corah")
	else
		return BuildAAIfNeeded(tskqbhvr, "armah")
	end
end


