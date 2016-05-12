shard_include "common"

local DebugEnabled = false


local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("CountHandler: " .. inStr)
	end
end

CountHandler = class(Module)

function CountHandler:Name()
	return "CountHandler"
end

function CountHandler:internalName()
	return "counthandler"
end

function CountHandler:Init()
	ai.factories = 0
	ai.maxFactoryLevel = 0
	ai.factoriesAtLevel = {}
	ai.outmodedFactoryID = {}

	ai.nameCount = {}
	ai.nameCountFinished = {}
	ai.lastNameCreated = {}
	ai.lastNameFinished = {}
	ai.lastNameDead = {}
	ai.mexCount = 0
	ai.conCount = 0
	ai.combatCount = 0
	ai.battleCount = 0
	ai.breakthroughCount = 0
	ai.siegeCount = 0
	ai.reclaimerCount = 0
	ai.assistCount = 0
	
	self:InitializeNameCounts()
end

function CountHandler:InitializeNameCounts()
	for name, t in pairs(unitTable) do
		ai.nameCount[name] = 0
	end
end

function CountHandler:UnitDamaged(unit, attacker,damage)
	local aname = "nil"
	if attacker then 
		if attacker:Team() ~= game:GetTeamID() then
			EchoDebug(unit:Name() .. " on team " .. unit:Team() .. " damaged by " .. attacker:Name() .. " on team " .. attacker:Team())
		end
	end
end

function CountHandler:UnitDead(unit)
	EchoDebug(unit:Name() .. " on team " .. unit:Team() .. " dead")
	if unit:Team() ~= game:GetTeamID() then
		EchoDebug("enemy unit died")
	end
end
