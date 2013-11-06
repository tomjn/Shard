require "unitlists"

NukeBehaviour = class(Behaviour)

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("NukeBehaviour: " .. inStr)
	end
end

local CMD_STOCKPILE = 100
local CMD_ATTACK = 20

function NukeBehaviour:Init()
    self.lastStockpileFrame = 0
    self.lastLaunchFrame = 0
end

function NukeBehaviour:UnitCreated(unit)

end

function NukeBehaviour:UnitIdle(unit)

end

function NukeBehaviour:Update()
	if self.active then
		local f = game:Frame()
		if self.lastStockpileFrame == 0 or f > self.lastStockpileFrame + 1500 then
			local floats = api.vectorFloat()
			floats:push_back(1)
			self.unit:Internal():ExecuteCustomCommand(CMD_STOCKPILE, floats)
			self.lastStockpileFrame = f
		end
		if f > self.lastLaunchFrame + 100 then
			local bestCell = ai.targethandler:GetBestNukeCell()
			if bestCell ~= nil then
				local position = bestCell.pos
				local floats = api.vectorFloat()
				-- populate with x, y, z of the position
				floats:push_back(position.x)
				floats:push_back(position.y)
				floats:push_back(position.z)
				self.unit:Internal():ExecuteCustomCommand(CMD_ATTACK, floats)
			end
			self.lastLaunchFrame = f
		end
	end
end

function NukeBehaviour:Activate()
	self.active = true
end

function NukeBehaviour:Deactivate()
	self.active = false
end

function NukeBehaviour:Priority()
	return 100
end

function NukeBehaviour:UnitDead(unit)

end
