--t1 ground

function BuildLLT(tskqbhvr)
	if tskqbhvr.unit == nil then
		return DummyUnitName
	end
	local unitName = DummyUnitName
		if MyTB.side == CORESideName then
			unitName = "corllt"
		else
			unitName = "armllt"
		end
		local unit = tskqbhvr.unit:Internal()
	return GroundDefenseIfNeeded(tskqbhvr,unitName)
end

function BuildSpecialLT(tskqbhvr)
	local unitName = DummyUnitName
	if IsAANeeded(tskqbhvr) then
		-- pop-up turrets are protected against bombs
		if MyTB.side == CORESideName then
			unitName = "cormaw"
		else
			unitName = "armclaw"
		end
	else
		if MyTB.side == CORESideName then
			unitName = "hllt"
		else
			unitName = "tawf001"
		end
	end
	local unit = tskqbhvr.unit:Internal()
	return GroundDefenseIfNeeded(tskqbhvr, unitName)
end

function BuildSpecialLTOnly(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "hllt"
	else
		unitName = "tawf001"
	end
	local unit = tskqbhvr.unit:Internal()
	return GroundDefenseIfNeeded(tskqbhvr, unitName)
end

function BuildHLT(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corhlt"
	else
		unitName = "armhlt"
	end
	local unit = tskqbhvr.unit:Internal()
	return GroundDefenseIfNeeded(tskqbhvr, unitName)
end

function BuildDepthCharge(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cordl"
	else
		unitName = "armdl"
	end
	return BuildTorpedoIfNeeded(tskqbhvr, unitName)
end

function BuildFloatHLT(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corfhlt"
	else
		unitName = "armfhlt"
	end
	local unit = tskqbhvr.unit:Internal()
	--return GroundDefenseIfNeeded(tskqbhvr, unitName)
	return unitName
end

--t2 ground
function BuildLvl2PopUp(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corvipe"
	else
		unitName = "armpb"
	end
	local unit = tskqbhvr.unit:Internal()
	return GroundDefenseIfNeeded(tskqbhvr, unitName)
end

function BuildTachyon(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cordoom"
	else
		unitName = "armanni"
	end
	local unit = tskqbhvr.unit:Internal()
	return GroundDefenseIfNeeded(tskqbhvr, unitName)
end

function BuildLightTorpedo(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cortl"
	else
		unitName = "armtl"
	end
	return BuildTorpedoIfNeeded(tskqbhvr,unitName)
end

function BuildPopTorpedo(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corptl"
	else
		unitName = "armptl"
	end
	return BuildTorpedoIfNeeded(tskqbhvr,unitName)
end

function BuildHeavyTorpedo(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "coratl"
	else
		unitName = "armatl"
	end
	return BuildTorpedoIfNeeded(tskqbhvr,unitName)
end

--AA

-- build AA in area only if there's not enough of it there already
--t1

function BuildLightAA(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = BuildAAIfNeeded(tskqbhvr, "corrl")
	else
		unitName = BuildAAIfNeeded(tskqbhvr, "armrl")
	end
	return unitName
end

function BuildFloatLightAA(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = BuildAAIfNeeded(tskqbhvr, "corfrt")
	else
		unitName = BuildAAIfNeeded(tskqbhvr, "armfrt")
	end
	return unitName
end

function BuildMediumAA(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = BuildAAIfNeeded(tskqbhvr, "madsam")
	else
		unitName = BuildAAIfNeeded(tskqbhvr, "packo")
	end
	return unitName
end

function BuildHeavyishAA(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = BuildAAIfNeeded(tskqbhvr, "corerad")
	else
		unitName = BuildAAIfNeeded(tskqbhvr, "armcir")
	end
	return unitName
end

--t2

function BuildHeavyAA(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = BuildAAIfNeeded(tskqbhvr, "corflak")
	else
		unitName = BuildAAIfNeeded(tskqbhvr, "armflak")
	end
	return unitName
end

function BuildFloatHeavyAA(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = BuildAAIfNeeded(tskqbhvr, "corenaa")
	else
		unitName = BuildAAIfNeeded(tskqbhvr, "armfflak")
	end
	return unitName
end

function BuildExtraHeavyAA(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = BuildAAIfNeeded(tskqbhvr, "screamer")
	else
		unitName = BuildAAIfNeeded(tskqbhvr, "mercury")
	end
	return unitName
end



--SONAR-RADAR

function BuildSonar(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corsonar"
	else
		unitName = "armsonar"
	end
	return unitName
end

function BuildRadar(tskqbhvr)
	local unitName = DummyUnitName
		if MyTB.side == CORESideName then
			unitName = "corrad"
		else
			unitName = "armrad"
		end
	return unitName
end

function BuildFloatRadar(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corfrad"
	else
		unitName = "armfrad"
	end
	return unitName
end

function BuildLvl1Jammer(tskqbhvr)
	if not IsJammerNeeded(tskqbhvr) then return DummyUnitName end
		if MyTB.side == CORESideName then
			return "corjamt"
		else
			return "armjamt"
		end
end

--t1

function BuildAdvancedSonar(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corason"
	else
		unitName = "armason"
	end
	return unitName
end

function BuildAdvancedRadar(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corarad"
	else
		unitName = "armarad"
	end
	return unitName
end

function BuildLvl2Jammer(tskqbhvr)
	if not IsJammerNeeded(tskqbhvr) then return DummyUnitName end
	if MyTB.side == CORESideName then
		return "corshroud"
	else
		return "armveil"
	end
end

--Anti Radar/Jammer/Minefield/ScoutSpam Weapon

function BuildAntiRadar(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cjuno"
	else
		unitName = "ajuno"
	end
	return unitName
end

--NUKE

function BuildAntinuke(tskqbhvr)
	if IsAntinukeNeeded(tskqbhvr) then
		local unitName = DummyUnitName
		if MyTB.side == CORESideName then
			unitName = "corfmd"
		else
			unitName = "armamd"
		end
		return unitName
	end
	return DummyUnitName
end

function BuildNuke(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corsilo"
	else
		unitName = "armsilo"
	end
	return BuildWithLimitedNumber(tskqbhvr, unitName, tskqbhvr.ai.overviewhandler.nukeLimit)
end

function BuildNukeIfNeeded(tskqbhvr)
	if IsNukeNeeded(tskqbhvr) then
		return BuildNuke(tskqbhvr)
	end
end

function BuildTacticalNuke(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cortron"
	else
		unitName = "armemp"
	end
	return BuildWithLimitedNumber(tskqbhvr, unitName, tskqbhvr.ai.overviewhandler.tacticalNukeLimit)
end

--PLASMA

function BuildLvl1Plasma(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corpun"
	else
		unitName = "armguard"
	end
	return unitName
end

function BuildLvl2Plasma(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cortoast"
	else
		unitName = "armamb"
	end
	return unitName
end

function BuildHeavyPlasma(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corint"
	else
		unitName = "armbrtha"
	end
	return BuildWithLimitedNumber(tskqbhvr, unitName, tskqbhvr.ai.overviewhandler.heavyPlasmaLimit)
end

function BuildLol(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corbuzz"
	else
		unitName = "armvulc"
	end
	return unitName
end

--plasma deflector

function BuildShield(tskqbhvr)
	if IsShieldNeeded(tskqbhvr) then
		local unitName = DummyUnitName
		if MyTB.side == CORESideName then
			unitName = "corgate"
		else
			unitName = "armgate"
		end
		return unitName
	end
	return DummyUnitName
end

--anti intrusion 

function BuildAntiIntr(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "corsd"
	else
		unitName = "armsd"
	end
	return unitName
end

--targeting facility

function BuildTargeting(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = "cortarg"
	else
		unitName = "armtarg"
	end
	return unitName
end

--ARM emp launcer

function BuildEmpLauncer(tskqbhvr)
	local unitName = DummyUnitName
	if MyTB.side == CORESideName then
		unitName = DummyUnitName
	else
		unitName = "armEmp"
	end
	return unitName
end

--Function of function

local function CommanderAA(tskqbhvr)
	local unitName = DummyUnitName
	if IsAANeeded(tskqbhvr) then
		if tskqbhvr.ai.maphandler:IsUnderWater(tskqbhvr.unit:Internal():GetPosition()) then
			unitName = BuildFloatLightAA(tskqbhvr)
		else
			unitName = BuildLightAA(tskqbhvr)
		end
	end
	return unitName
end
