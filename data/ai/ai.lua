require "api"
require "spothandler"
require "behaviour"
require "behaviourfactory"
require "unit"
require "unithandler"
require "attackhandler"

AI = class(AIBase)

function AI:Init()

	game:SendToConsole("OHAI DER")
	game:SendToConsole("Shard by AF - playing:"..game:GameName().." on:"..game.map:MapName())

	self.unithandler = UnitHandler()
	self.unithandler:Init()

	self.attackhandler = AttackHandler()
	self.attackhandler:Init()

	self.metalspothandler = MetalSpotHandler()
	self.metalspothandler:Init()
end

function AI:Update()
	if self.gameend == true then
		return
	end
	
	local x = os.clock()
	
	local mx = os.clock()
	self.metalspothandler:Update()
	mx = (os.clock() - mx)
	
	local ax = os.clock()
	self.attackhandler:Update()
	ax = (os.clock() - ax)
	
	local ux = os.clock()
	self.unithandler:Update()
	ux = (os.clock() - ux)
	
	local ti = (os.clock() - x)
	if ti > 0.0252 then
		if mx > 0.0084 then
			game:SendToConsole("mspot handler update time: "..mx)
		end
		if ax > 0.0084 then
			game:SendToConsole("atkhandler update time: "..ax)
		end
		if ux > 0.0084 then
			game:SendToConsole("unithandler update time: "..ux)
		end
	end
	--game:SendToConsole("test is "..game:Test())
	--t = game:GetEnemies()
	--if t == nil then
	--	game:SendToConsole("t is nil! ")
	--else
	--	game:SendToConsole("enemycount: "..#t)
	--end
end

function AI:UnitCreated(unit)
	if self.gameend == true then
		return
	end
	if unit == nil then
		game:SendToConsole("shard found nil unit")
		return
	end
	self.metalspothandler:UnitCreated(unit)
	self.attackhandler:UnitCreated(unit)
	self.unithandler:UnitCreated(unit)
end

function AI:UnitBuilt(unit)
	if self.gameend == true then
		return
	end
	if unit == nil then
		game:SendToConsole("shard-warning: unitbuilt nil ")
		return
	end
	self.metalspothandler:UnitBuilt(unit)
	self.attackhandler:UnitBuilt(unit)
	self.unithandler:UnitBuilt(unit)
end

function AI:UnitDead(unit)
	if self.gameend == true then
		return
	end
	if unit == nil then
		return
	end
	self.metalspothandler:UnitDead(unit)
	self.attackhandler:UnitDead(unit)
	self.unithandler:UnitDead(unit)
end

function AI:UnitIdle(unit)
	if self.gameend == true then
		return
	end
	if unit == nil then
		game:SendToConsole("shard-warning: idle unit nil")
		return
	end
	
	local x = os.clock()
	
	self.metalspothandler:UnitIdle(unit)
	self.attackhandler:UnitIdle(unit)
	self.unithandler:UnitIdle(unit)
	
	local ti = (os.clock() - x)
	if ti > 0.02 then
		game:SendToConsole("unitidle time: "..ti)
	end
end

function AI:UnitDamaged(unit,attacker)
	if self.gameend == true then
		return
	end
	if unit == nil then
		return
	end
	self.metalspothandler:UnitDamaged(unit,attacker)
	self.attackhandler:UnitDamaged(unit,attacker)
	self.unithandler:UnitDamaged(unit,attacker)
end

function AI:GameEnd()
	self.gameend = true
end
-- create and use an AI
ai = AI()


