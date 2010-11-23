require "api"
require "behaviourfactory"
require "unit"
require "module"
require "modules"

AI = class(AIBase)

function AI:Init()

	game:SendToConsole("OHAI DER")
	game:SendToConsole("Shard by AF - playing:"..game:GameName().." on:"..game.map:MapName())

	self.modules = {}
	for i,m in ipairs(modules) do
		newmodule = m()
		local internalname = newmodule:internalName()
		
		self[internalname] = newmodule
		table.insert(self.modules,newmodule)
		newmodule:Init()
		game:SendToConsole("added "..newmodule:Name().." module")
	end
end

function AI:Update()
	if self.gameend == true then
		return
	end
	for i,m in ipairs(self.modules) do
		if m == nil then
			game:SendToConsole("nil module!")
		else
			m:Update()
		end
	end
end

function AI:UnitCreated(unit)
	if self.gameend == true then
		return
	end
	if unit == nil then
		game:SendToConsole("shard found nil unit")
		return
	end
	for i,m in ipairs(self.modules) do
		m:UnitCreated(unit)
	end
end

function AI:UnitBuilt(unit)
	if self.gameend == true then
		return
	end
	if unit == nil then
		game:SendToConsole("shard-warning: unitbuilt nil ")
		return
	end
	for i,m in ipairs(self.modules) do
		m:UnitBuilt(unit)
	end
end

function AI:UnitDead(unit)
	if self.gameend == true then
		return
	end
	if unit == nil then
		return
	end
	for i,m in ipairs(self.modules) do
		m:UnitDead(unit)
	end
end

function AI:UnitIdle(unit)
	if self.gameend == true then
		return
	end
	if unit == nil then
		game:SendToConsole("shard-warning: idle unit nil")
		return
	end
	
	for i,m in ipairs(self.modules) do
		m:UnitIdle(unit)
	end
end

function AI:UnitDamaged(unit,attacker)
	if self.gameend == true then
		return
	end
	if unit == nil then
		return
	end
	for i,m in ipairs(self.modules) do
		m:UnitDamaged(unit,attacker)
	end
end

function AI:GameEnd()
	self.gameend = true
	for i,m in ipairs(self.modules) do
		m:GameEnd(unit)
	end
end
-- create and use an AI
ai = AI()


