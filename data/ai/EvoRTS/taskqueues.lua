--[[
Task Queues!
]]--

math.randomseed( os.time() )
math.random(); math.random(); math.random()

local function AirOrLand()
   if (ai.factories < 4) or (ai.factories == nil) then
		local r = math.random(0,4)
		if r == 0 then
			return "ebasefactory"
		elseif r == 1 then
			return "eairplant"
		elseif r == 2 then
			return "eamphibfac"
		else 
			return "eminifac"
		end
	end
end

local factory = {
   "eengineer5",
   "eengineer5",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "elighttank3",
   "eengineer5",
   "eengineer5",
   "eriottank2",
   "elighttank3",
   "elighttank3",
   "eriottank2",
   "eengineer5",
    "eflametank",
   "elighttank3",
    "eflametank",
   "elighttank3",
    "eflametank",
   "eriottank2",
   "eengineer5",
   "eriottank2",
   "efatso2",
   "emediumtank3",
   "eaatank",
   "emediumtank3",
   "emediumtank3",
   "emediumtank3",
   "eengineer5",
   "efatso2",
   "elighttank3",
    "eflametank",
   "elighttank3",
   "eaatank",
    "eflametank",
   "elighttank3",
   "eartytank",
    "eflametank",
   "eriottank2",
   "eriottank2",
   "efatso2",
   "efatso2",
   "eartytank",
   "efatso2",
   "eheavytank3",
   "emissiletank",
   "efatso2",
   "emissiletank",
   "efatso2",
   "emissiletank",
}

local firstEngineer = {
   "emetalextractor",
   "emetalextractor",
   "emetalextractor",
   "ebasefactory",
   "esolar2",
   "esolar2",
   "elightturret2",
   "elightturret2",
   "emetalextractor",
   "emetalextractor",
   "emetalextractor",
   "elightturret2",
   "efusion2",
   "emetalextractor",
   "emetalextractor",
   "emetalextractor",
   "emetalextractor",
   "esolar2",
   "esolar2",
   "emetalextractor",
   "eaaturret",
   "emetalextractor",
   "emetalextractor",
   "elightturret2",
   "emetalextractor",
   "eaaturret",
   AirOrLand,
   "emetalextractor",
   "esolar2",
   "emetalextractor",
   "ejammer2",
   "estorage",
   "emetalextractor",
   "emetalextractor",
   "estorage",
   "emetalextractor",
   "emetalextractor",
   "elightturret2",
   "eaaturret",
   "eheavyturret2",
   "efusion2",
}

local engineers = {
   "emetalextractor",
   "emetalextractor",
   "emetalextractor",
   "esolar2",
   "emetalextractor",
   "elightturret2",
   "emetalextractor",
   "emetalextractor",
   "elightturret2",
   "efusion2",
   AirOrLand,
   "eaaturret",
   "emetalextractor",
   "emetalextractor",
   "emetalextractor",
   "esolar2",
   "emetalextractor",
   "esolar2",
   "emetalextractor",
   "eaaturret",
   "emetalextractor",
   "esolar2",
   "emetalextractor",
   "elightturret2",
   "emetalextractor",
   "emetalextractor",
   "esolar2",
   "emetalextractor",
   "ejammer2",
   "esolar2",
   "elrpc",
   "efusion2",
   "eheavyturret2",
   "efusion2",
   "esolar2",
   "emetalextractor",
   "emetalextractor",
   "eheavyturret2",
   "estorage",
   "emetalextractor",
   "emetalextractor",
   "eheavyturret2",
   "estorage",
   "eaaturret",
   "estorage",
   "efusion2",
}

local airplant = {
   "eairengineer",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
   "eairengineer",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
   "eairengineer",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
   "efighter",
   "ebomber",
   "ebomber",
   "egunship2",
   "egunship2",
}

local amphibfactory = {
   "eamphibengineer",
   "eamphibbuggy",
   "eamphibbuggy",
   "eamphibbuggy",
   "eamphibmedtank",
   "eamphibmedtank",
   "eamphibmedtank",
   "eamphibriot",
   "eamphibriot",
   "eamphibrock",
   "eamphibrock",
   "eamphibrock",
   "eamphibrock",
   "eamphibarty",
   "eamphibarty",
   "eamphibarty",
   "eamphibbuggy",
   "eamphibbuggy",
   "eamphibbuggy",
   "eamphibmedtank",
   "eamphibmedtank",
   "eamphibmedtank",
   "eamphibriot",
   "eamphibriot",
   "eamphibrock",
   "eamphibrock",
   "eamphibrock",
   "eamphibrock",
   "eamphibarty",
   "eamphibarty",
   "eamphibarty",
   "eamphibengineer",
   "eamphibbuggy",
   "eamphibbuggy",
   "eamphibbuggy",
   "eamphibmedtank",
   "eamphibmedtank",
   "eamphibmedtank",
   "eamphibriot",
   "eamphibriot",
   "eamphibrock",
   "eamphibrock",
   "eamphibrock",
   "eamphibrock",
   "eamphibarty",
   "eamphibarty",
   "eamphibarty",
   "eamphibengineer",
   "eamphibbuggy",
   "eamphibbuggy",
   "eamphibbuggy",
   "eamphibmedtank",
   "eamphibmedtank",
   "eamphibmedtank",
   "eamphibriot",
   "eamphibriot",
   "eamphibrock",
   "eamphibrock",
   "eamphibrock",
   "eamphibrock",
   "eamphibarty",
   "eamphibarty",
   "eamphibarty",   
}

local allterrfactory = {
   "eallterrengineer",
   "eallterrlight",
   "eallterrlight",
   "eallterrlight",
   "eallterrlight",
   "eallterrriot",
   "eallterrriot",
   "eallterrmed",
   "eallterrmed",
   "eallterrmed",
   "eallterrmed",
   "eallterrheavy",
   "eallterrheavy",
   "eallterrheavy",
   "eallterrengineer",
   "eallterrlight",
   "eallterrlight",
   "eallterrlight",
   "eallterrlight",
   "eallterrriot",
   "eallterrriot",
   "eallterrmed",
   "eallterrmed",
   "eallterrmed",
   "eallterrmed",
   "eallterrheavy",
   "eallterrheavy",
   "eallterrheavy",
   "eallterrengineer",
   "eallterrlight",
   "eallterrlight",
   "eallterrlight",
   "eallterrlight",
   "eallterrriot",
   "eallterrriot",
   "eallterrmed",
   "eallterrmed",
   "eallterrmed",
   "eallterrmed",
   "eallterrheavy",
   "eallterrheavy",
   "eallterrheavy",
   "eallterrengineer",
   "eallterrlight",
   "eallterrlight",
   "eallterrlight",
   "eallterrlight",
   "eallterrriot",
   "eallterrriot",
   "eallterrmed",
   "eallterrmed",
   "eallterrmed",
   "eallterrmed",
   "eallterrheavy",
   "eallterrheavy",
   "eallterrheavy",   
}

local function engineerlist(beh)
   if ai.engineerfirst == true then
      return engineers
   else
      ai.engineerfirst = true
      return firstEngineer
   end
end

taskqueues = {
   ecommander = engineerlist,
   ebasefactory = factory,
   eengineer5 = engineerlist,
   eallterrengineer = engineerlist,
   eamphibengineer = engineerlist,
   eairengineer = engineerlist,
   eairplant = airplant,
   eamphibfac = amphibfactory,
   eminifac = allterrfactory,
   
}