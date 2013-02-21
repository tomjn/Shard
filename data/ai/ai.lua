require "api"
require "behaviourfactory"
require "unit"
require "module"
require "modules"

AI = class(AIBase)

function AI:Init()
	game:SendToConsole("Shard by AF - playing:"..game:GameName().." on:"..game.map:MapName())

	self.modules = {}
	if next(modules) ~= nil then
		for i,m in ipairs(modules) do
			newmodule = m()
			local internalname = newmodule:internalName()
			
			self[internalname] = newmodule
			table.insert(self.modules,newmodule)
			newmodule:Init()
			game:SendToConsole("added "..newmodule:Name().." module")
		end
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

function AI:UnitCreated(engineunit)
	if self.gameend == true then
		return
	end
	if engineunit == nil then
		game:SendToConsole("shard found nil engineunit")
		return
	end
	for i,m in ipairs(self.modules) do
		m:UnitCreated(engineunit)
	end
end

function AI:UnitBuilt(engineunit)
	if self.gameend == true then
		return
	end
	if engineunit == nil then
		game:SendToConsole("shard-warning: unitbuilt engineunit nil ")
		return
	end
	for i,m in ipairs(self.modules) do
		m:UnitBuilt(engineunit)
	end
end

function AI:UnitDead(engineunit)
	if self.gameend == true then
		return
	end
	if engineunit == nil then
		return
	end
	for i,m in ipairs(self.modules) do
		m:UnitDead(engineunit)
	end
end

function AI:UnitIdle(engineunit)
	if self.gameend == true then
		return
	end
	if engineunit == nil then
		game:SendToConsole("shard-warning: idle engineunit nil")
		return
	end
	
	for i,m in ipairs(self.modules) do
		m:UnitIdle(engineunit)
	end
end

function AI:UnitDamaged(engineunit,engineattacker)
	if self.gameend == true then
		return
	end
	if engineunit == nil then
		return
	end
	for i,m in ipairs(self.modules) do
		m:UnitDamaged(engineunit,engineattacker)
	end
end

function AI:UnitMoveFailed(engineunit)
	if self.gameend == true then
		return
	end
	if engineunit == nil then
		return
	end
	for i,m in ipairs(self.modules) do
		m:UnitMoveFailed(engineunit)
	end
end

function AI:GameEnd()
	self.gameend = true
	for i,m in ipairs(self.modules) do
		m:GameEnd()
	end
end
-- create and use an AI
ai = AI()


