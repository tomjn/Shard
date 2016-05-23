function widget:GetInfo()
    return {
        name      = "Shard Unittable exporter", --(v0.5)
        desc      = "Exports the unittable for shard",
        author    = "Beherith",
        date      = "2016-03-22",
        license   = "GPL V2",
        layer     = -10000,
        enabled   = true,
    }
end
 
--name   radarRadius   techLevel   isBuilding   needsWater   extractsMetal   bigExplosion   airLosRadius   losRadius   sonarRadius   metalCost   xsize   totalEnergyOut   jammerRadius   wreckName   zsize   mtype   airRange   submergedRange   stealth   groundRange   isWeapon   factoriesCanBuild   "armaap"   "armplat"   "armlab"   "armalab"   "armsy"   "armasy"   "asubpen"   "armavp"   "armvp"   "armap"   "armhp"   "armfhp"   "coraap"   "corplat"   "corlab"   "coralab"   "corsy"   "corasy"   "csubpen"   "coravp"   "corvp"   "corap"   "corhp"   "corfhp"
 
--hard ones: mtype,factoriesCanBuild
local ut=''
function widget:Initialize()
    bigExplosions = {commander_blast = true, atomic_blast = true,}
        for id,unitDef in pairs(UnitDefs) do
        if unitDef.techLevel >=0 then
            str= '\n'..'\n' .."unitTable[\"" .. unitDef.name..'\"] = {'..'\n'
           
            str = str .. 'radarRadius = ' .. tostring(unitDef.radarRadius) .. ','
            str = str .. 'isBuilding = ' .. tostring(unitDef.isBuilding) .. ','
            str = str .. 'needsWater = ' .. tostring(unitDef.minWaterDepth >0 ) .. ','
            str = str .. 'extractsMetal = ' .. tostring(unitDef.extractsMetal) .. ','
            str = str .. 'techLevel = ' .. tostring(unitDef.techLevel) .. ','
	    Spring.Echo(unitDef.deathExplosion)
	    if unitDef.deathExplosion == ('atomic_blast' or 'nuclear_missile') then 
		    str = str .. 'bigExplosion = ' .. tostring(true) .. ','
	    else
		    str = str .. 'bigExplosion = ' .. tostring(false) .. ','
	    end
            str = str .. 'airLosRadius = ' .. tostring(unitDef.airLosRadius) .. ','
            str = str .. 'losRadius = ' .. tostring(unitDef.losRadius) .. ','
            str = str .. 'sonarRadius = ' .. tostring(unitDef.sonarRadius) .. ','
            str = str .. 'metalCost = ' .. tostring(unitDef.metalCost) .. ','
            str = str .. 'energyCost = ' .. tostring(unitDef.energyCost) .. ','
            str = str .. 'buildTime = ' .. tostring(unitDef.buildTime) .. ','
            str = str .. 'xsize = ' .. tostring(unitDef.xsize ) .. ','
            str = str .. 'zsize = ' .. tostring(unitDef.zsize ) .. ','
            str = str .. 'totalEnergyOut = ' .. tostring(unitDef.totalEnergyOut) .. ','
            str = str .. 'jammerRadius = ' .. tostring(unitDef.jammerRadius) .. ','
            str = str .. 'canFly = ' .. tostring(unitDef.canFly) .. ','
            if unitDef.wreckName ~= '' then str = str .. 'wreckName = \"' .. tostring(unitDef.wreckName) .. '\",' end
           
           
            groundRange = 0
            submergedRange = 0
            airRange = 0
            isWeapon = false
            for weaponindex, weaponInfo in ipairs(unitDef.weapons) do
                isWeapon = true
                weaponDefID = weaponInfo.weaponDef
                --Spring.Echo(unitDef.name,'onlytargets:',to_string(weaponInfo.onlyTargets))
                if weaponInfo.onlyTargets["vtol"] then
                    airRange = math.max(airRange,WeaponDefs[weaponDefID].range)
                elseif WeaponDefs[weaponDefID].type == "TorpedoLauncher" then
                    submergedRange = math.max(submergedRange,WeaponDefs[weaponDefID].range)
                else
                    groundRange = math.max(groundRange,WeaponDefs[weaponDefID].range)
                end
            end
           
            str = str .. 'airRange = ' .. tostring(airRange) .. ','
            str = str .. 'groundRange = ' .. tostring(groundRange) .. ','
            str = str .. 'submergedRange = ' .. tostring(submergedRange) .. ','
            str = str .. 'isWeapon = ' .. tostring(isWeapon) .. ','
            
	    if #unitDef.buildOptions >0 then
		    local canbuild = '{'
		str = str .. 'buildOptions = ' .. 'true'.. ','
		for index,defID in pairs(unitDef.buildOptions) do
			if #UnitDefs[defID].buildOptions >0 and UnitDefs[defID].isBuilding then
				--Spring.Echo(unitDef.name,UnitDefs[defID].name)
				canbuild= canbuild .. '"'.. UnitDefs[defID].name .. '"' .. ', '
			end
			

		end
		if canbuild ~= '{' then 
			str = str .. 'canbuild = ' .. tostring(canbuild) .. '}' .. ','
		end
		
	    else
		str = str .. 'buildOptions = ' .. 'false'.. ','
	    end
           
            mtype = 'veh' -- buildings are veh, possible types are veh,bot,shp,hov,sub,air,amp
           
            if unitDef.moveDef and unitDef.moveDef.name then
                -- Spring.Echo(unitDef.name,"unitDef.moveDef",to_string(unitDef.moveDef))
                if unitDef.moveDef.name:find('uboat') ~= nil then
                    mtype = 'sub'
                elseif  unitDef.moveDef.name:find('boat') ~= nil then
                    mtype = 'shp'
                elseif  unitDef.moveDef.name:find('hover') ~= nil then
                    mtype = 'hov'
                elseif  unitDef.moveDef.name:find('akbot') ~= nil then
                    mtype = 'amp'
                elseif  unitDef.moveDef.name:find('atank') ~= nil then
                    mtype = 'amp'
                end
            end
            if unitDef.canfly then
                mtype = "air"
            end
            str = str .. 'mtype = \"' .. tostring(mtype) .. '\",'
           
            str = str .. '}'
            --Spring.Echo(str)
            ut=ut..str
            str = ""
           
        end
    end
    local a = io.open('unittable.lua','w')
    a:write(ut)
    a:close()
end
 
function to_string(data, indent)
   local str = ""
 
   if(indent == nil) then
      indent = 0
   end
 
   -- Check the type
   if(type(data) == "string") then
      str = str .. ("    "):rep(indent) .. data .. "\n"
   elseif(type(data) == "number") then
      str = str .. ("    "):rep(indent) .. data .. "\n"
   elseif(type(data) == "boolean") then
      if(data == true) then
         str = str .. "true"
      else
         str = str .. "false"
      end
   elseif(type(data) == "table") then
      local i, v
      for i, v in pairs(data) do
         -- Check for a table in a table
         if(type(v) == "table") then
            str = str .. ("    "):rep(indent) .. i .. ":\n"
            str = str .. to_string(v, indent + 2)
         else
            str = str .. ("    "):rep(indent) .. i .. ": " .. to_string(v, 0)
         end
      end
   elseif (data ==nil) then
      str=str..'nil'
   else
      --print_debug(1, "Error: unknown data type: %s", type(data))
      str=str.. "Error: unknown data type:" .. type(data)
      Spring.Echo('X data type')
   end
 
   return str
end

--[[
					A LIST WITH ALL POSSIBLE VOICE OF THE UNIT DEFINITION CAN BE USEFULL
[f=-000001] activateWhenBuilt, true
[f=-000001] airLosRadius, 273
[f=-000001] airStrafe, true
[f=-000001] armorType, 5
[f=-000001] armoredMultiple, 1
[f=-000001] autoHeal, 0
[f=-000001] bankingAllowed, true
[f=-000001] buildDistance, 128
[f=-000001] buildOptions, <table>
[f=-000001] buildRange3D, false
[f=-000001] buildSpeed, 0
[f=-000001] buildTime, 1875
[f=-000001] buildingDecalDecaySpeed, 30
[f=-000001] buildingDecalSizeX, 5
[f=-000001] buildingDecalSizeY, 5
[f=-000001] buildingDecalType, -1
[f=-000001] buildpicname, ARMUWMEX.DDS
[f=-000001] canAssist, false
[f=-000001] canAttack, true
[f=-000001] canBeAssisted, true
[f=-000001] canCapture, false
[f=-000001] canCloak, false
[f=-000001] canDropFlare, false
[f=-000001] canFight, true
[f=-000001] canFireControl, true
[f=-000001] canFly, false
[f=-000001] canGuard, true
[f=-000001] canKamikaze, false
[f=-000001] canLoopbackAttack, false
[f=-000001] canManualFire, false
[f=-000001] canMove, false
[f=-000001] canPatrol, true
[f=-000001] canReclaim, false
[f=-000001] canRepair, false
[f=-000001] canRepeat, true
[f=-000001] canRestore, false
[f=-000001] canResurrect, false
[f=-000001] canSelfD, true
[f=-000001] canSelfRepair, false
[f=-000001] canSubmerge, false
[f=-000001] cantBeTransported, true
[f=-000001] capturable, true
[f=-000001] captureSpeed, 0
[f=-000001] cloakCost, 0
[f=-000001] cloakCostMoving, 0
[f=-000001] cloakTimeout, 128
[f=-000001] cobID, -1
[f=-000001] collide, true
[f=-000001] collisionVolume, <table>
[f=-000001] crashDrag, 0.005
[f=-000001] customParams, <table>
[f=-000001] deathExplosion,
[f=-000001] decloakDistance, 0
[f=-000001] decloakOnFire, true
[f=-000001] decloakSpherical, true
[f=-000001] decoyDef, nil
[f=-000001] dlHoverFactor, -1
[f=-000001] energyCost, 719
[f=-000001] energyMake, 0
[f=-000001] energyStorage, 0
[f=-000001] energyUpkeep, 0
[f=-000001] extractRange, 90
[f=-000001] extractsMetal, 0.001
[f=-000001] factoryHeadingTakeoff, true
[f=-000001] fallSpeed, 0.2
[f=-000001] fireState, -1
[f=-000001] flankingBonusDirX, 0
[f=-000001] flankingBonusDirY, 0
[f=-000001] flankingBonusDirZ, 1
[f=-000001] flankingBonusMax, 1.89999998
[f=-000001] flankingBonusMin, 0.89999998
[f=-000001] flankingBonusMobilityAdd, 0.01
[f=-000001] flankingBonusMode, 1
[f=-000001] flareDelay, 0.30000001
[f=-000001] flareDropVectorX, 0
[f=-000001] flareDropVectorY, 0
[f=-000001] flareDropVectorZ, 0
[f=-000001] flareEfficiency, 0.5
[f=-000001] flareReloadTime, 5
[f=-000001] flareSalvoDelay, 0
[f=-000001] flareSalvoSize, 4
[f=-000001] flareTime, 90
[f=-000001] floatOnWater, false
[f=-000001] frontToSpeed, 0.1
[f=-000001] fullHealthFactory, false
[f=-000001] health, 180
[f=-000001] height, 46
[f=-000001] hideDamage, false
[f=-000001] highTrajectoryType, 0
[f=-000001] holdSteady, false
[f=-000001] hoverAttack, false
[f=-000001] humanName, Underwater Metal Extractor
[f=-000001] iconType, m.user
[f=-000001] id, 168
[f=-000001] idleAutoHeal, 2.5
[f=-000001] idleTime, 1800
[f=-000001] isAirBase, false
[f=-000001] isAirUnit, false
[f=-000001] isBomberAirUnit, false
[f=-000001] isBuilder, false
[f=-000001] isBuilding, true
[f=-000001] isExtractor, true
[f=-000001] isFactory, false
[f=-000001] isFeature, false
[f=-000001] isFighterAirUnit, false
[f=-000001] isFirePlatform, false
[f=-000001] isGroundUnit, false
[f=-000001] isHoveringAirUnit, false
[f=-000001] isImmobile, true
[f=-000001] isMobileBuilder, false
[f=-000001] isStaticBuilder, false
[f=-000001] isStrafingAirUnit, false
[f=-000001] isTransport, false
[f=-000001] jammerRadius, 0
[f=-000001] kamikazeDist, 0
[f=-000001] kamikazeUseLOS, false
[f=-000001] leaveTracks, false
[f=-000001] levelGround, true
[f=-000001] loadingRadius, 220
[f=-000001] losHeight, 20
[f=-000001] losRadius, 182
[f=-000001] makesMetal, 0
[f=-000001] mass, 59
[f=-000001] maxAcc, 0
[f=-000001] maxAileron, 0.015
[f=-000001] maxBank, 0.80000001
[f=-000001] maxCoverage, 0
[f=-000001] maxDec, 0
[f=-000001] maxElevator, 0.01
[f=-000001] maxHeightDif, 17.8091469
[f=-000001] maxPitch, 0.44999999
[f=-000001] maxRepairSpeed, 0
[f=-000001] maxRudder, 0.004
[f=-000001] maxThisUnit, 32000
[f=-000001] maxWaterDepth, 10000000
[f=-000001] maxWeaponRange, 0
[f=-000001] metalCost, 59
[f=-000001] metalMake, 0
[f=-000001] metalStorage, 50
[f=-000001] metalUpkeep, 0
[f=-000001] minCollisionSpeed, 1
[f=-000001] minWaterDepth, 15
[f=-000001] modCategories, <table>
[f=-000001] model, <table>
[f=-000001] modelname, deprecated! use def.model.path instead!
[f=-000001] moveDef, <table>
[f=-000001] moveState, 1
[f=-000001] myGravity, 0.40000001
[f=-000001] name, armuwmex
[f=-000001] nanoColorB, 0.2
[f=-000001] nanoColorG, 0.69999999
[f=-000001] nanoColorR, 0.2
[f=-000001] needGeo, false
[f=-000001] noChaseCategories, <table>
[f=-000001] onOffable, true
[f=-000001] power, 70.9833374
[f=-000001] rSpeed, 0
[f=-000001] radarRadius, 0
[f=-000001] radius, 28
[f=-000001] reclaimSpeed, 0
[f=-000001] reclaimable, true
[f=-000001] releaseHeld, false
[f=-000001] repairSpeed, 0
[f=-000001] repairable, true
[f=-000001] resurrectSpeed, 0
[f=-000001] scriptName, armuwmex.cob
[f=-000001] scriptPath, armuwmex.cob
[f=-000001] seismicRadius, 0
[f=-000001] seismicSignature, 0
[f=-000001] selfDCountdown, 1
[f=-000001] selfDExplosion,
[f=-000001] shieldWeaponDef, nil
[f=-000001] showNanoFrame, true
[f=-000001] showNanoSpray, true
[f=-000001] showPlayerName, false
[f=-000001] slideTolerance, 0
[f=-000001] sonarJamRadius, 0
[f=-000001] sonarRadius, 0
[f=-000001] sonarStealth, false
[f=-000001] sounds, <table>
[f=-000001] speed, 0
[f=-000001] speedToFront, 0.07
[f=-000001] springCategories, <table>
[f=-000001] startCloaked, false
[f=-000001] stealth, false
[f=-000001] stockpileWeaponDef, nil
[f=-000001] strafeToAttack, false
[f=-000001] targfac, false
[f=-000001] techLevel, 1
[f=-000001] terraformSpeed, 0
[f=-000001] tidalGenerator, 0
[f=-000001] tooltip,
[f=-000001] totalEnergyOut, 0
[f=-000001] trackOffset, 0
[f=-000001] trackStrength, 0
[f=-000001] trackStretch, 1
[f=-000001] trackType, -1
[f=-000001] trackWidth, 32
[f=-000001] transportByEnemy, false
[f=-000001] transportCapacity, 0
[f=-000001] transportMass, 100000
[f=-000001] transportSize, 0
[f=-000001] transportUnloadMethod, 0
[f=-000001] turnInPlace, true
[f=-000001] turnInPlaceSpeedLimit, 0
[f=-000001] turnRadius, 500
[f=-000001] turnRate, 0
[f=-000001] unitFallSpeed, 0
[f=-000001] upright, true
[f=-000001] useBuildingGroundDecal, true
[f=-000001] useSmoothMesh, true
[f=-000001] verticalSpeed, 3
[f=-000001] wantedHeight, 0
[f=-000001] waterline, 0
[f=-000001] weapons, <table>
[f=-000001] windGenerator, 0
[f=-000001] wingAngle, 0.08
[f=-000001] wingDrag, 0.07
[f=-000001] wreckName, armuwmex_dead
[f=-000001] xsize, 6
[f=-000001] zsize, 6
[f=-000001] pairs, <function>
[f=-000001] cost, 70.9833374
[f=-000001] shieldPower, -1
[f=-000001] next, <function>
[f=-000001] reloadTime, 0
[f=-000001] canParalyze, false
[f=-000001] wDefs, <table>
[f=-000001] canStockpile, false
[f=-000001] hasShield, false
[f=-000001] canAttackWater, false
[f=-000001] primaryWeapon, 0
]]--