require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("BomberHandler: " .. inStr)
	end
end

BomberHandler = class(Module)

function BomberHandler:Name()
	return "BomberHandler"
end

function BomberHandler:internalName()
	return "bomberhandler"
end

function BomberHandler:Init()
	self.recruits = {}
	self.counter = baseBomberCounter
	ai.hasBombed = 0
	ai.couldBomb = 0
end

function BomberHandler:Update()
	local f = game:Frame()
	if math.mod(f,90) == 0 then
		self:DoTargetting()
	end
end

function BomberHandler:GameEnd()
	--
end

function BomberHandler:UnitCreated(engineunit)
	--
end

function BomberHandler:UnitBuilt(engineunit)
	--
end

function BomberHandler:UnitIdle(engineunit)
	--
end

function BomberHandler:DoTargetting()
	if #self.recruits >= self.counter then
		ai.couldBomb = ai.couldBomb + 1
		-- find somewhere to attack
		local bombTarget = ai.targethandler:GetBestBomberTarget()

		if bombTarget ~= nil then
			for i,recruit in ipairs(self.recruits) do
				recruit:BombTarget(bombTarget)
			end
			self.recruits = {}
			ai.hasBombed = ai.hasBombed + 1
		end
	end
end

function BomberHandler:IsRecruit(attkbehaviour)
	for i,v in ipairs(self.recruits) do
		if v == attkbehaviour then
			return true
		end
	end
	return false
end

function BomberHandler:AddRecruit(attkbehaviour)
	if not self:IsRecruit(attkbehaviour) then
		table.insert(self.recruits,attkbehaviour)
	end
end

function BomberHandler:RemoveRecruit(attkbehaviour)
	for i,v in ipairs(self.recruits) do
		if v == attkbehaviour then
			table.remove(self.recruits, i)
			return true
		end
	end
	return false
end

function BomberHandler:NeedMore()
	self.counter = self.counter + 1
	self.counter = math.min(self.counter, maxBomberCounter)
	-- EchoDebug("bomber counter: " .. self.counter .. " (bomber died)")
end

function BomberHandler:NeedLess()
	self.counter = self.counter - 1
	self.counter = math.max(self.counter, minBomberCounter)
	EchoDebug("bomber counter: " .. self.counter .. " (AA died)")
end

function BomberHandler:GetCounter()
	return self.counter
end