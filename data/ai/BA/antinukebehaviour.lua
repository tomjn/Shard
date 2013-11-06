require "unitlists"

AntinukeBehaviour = class(Behaviour)

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("AntinukeBehaviour: " .. inStr)
	end
end

local CMD_STOCKPILE = 100

function AntinukeBehaviour:Init()
    self.lastStockpileFrame = 0
end

function AntinukeBehaviour:UnitCreated(unit)

end

function AntinukeBehaviour:UnitIdle(unit)

end

function AntinukeBehaviour:Update()
	if self.active then
		local f = game:Frame()
		if self.lastStockpileFrame == 0 or f > self.lastStockpileFrame + 1000 then
			local floats = api.vectorFloat()
			floats:push_back(1)
			self.unit:Internal():ExecuteCustomCommand(CMD_STOCKPILE, floats)
			self.lastStockpileFrame = f
		end
	end
end

function AntinukeBehaviour:Activate()
	self.active = true
end

function AntinukeBehaviour:Deactivate()
	self.active = false
end

function AntinukeBehaviour:Priority()
	if ai.needAntinuke then
		return 100
	else
		return 0
	end
end

function AntinukeBehaviour:UnitDead(unit)

end
