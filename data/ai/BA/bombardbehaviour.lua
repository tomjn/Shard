require "unitlists"

BombardBehaviour = class(Behaviour)

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("BombardBehaviour: " .. inStr)
	end
end

local CMD_ATTACK = 20

function BombardBehaviour:Init()
    self.lastShootFrame = 0
end

function BombardBehaviour:UnitCreated(unit)

end

function BombardBehaviour:UnitIdle(unit)
	if self.active then
		local f = game:Frame()
		if self.lastShootFrame == 0 or f > self.lastShootFrame + 350 then
			EchoDebug("cannon idle")
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
			self.lastShootFrame = f
		end
	end
end

function BombardBehaviour:Update()

end

function BombardBehaviour:Activate()
	self.active = true
end

function BombardBehaviour:Deactivate()
	self.active = false
end

function BombardBehaviour:Priority()
	return 100
end

function BombardBehaviour:UnitDead(unit)

end
