require "common"


BombardBehaviour = class(Behaviour)

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("BombardBehaviour: " .. inStr)
	end
end

local CMD_ATTACK = 20

local valueThreatThreshold = 1600 -- anything above this level of value+threat will be shot at even if the cannon isn't idle

function BombardBehaviour:Init()
    self.lastFireFrame = 0
    local unit = self.unit:Internal()
    self.position = unit:GetPosition()
    self.range = unitTable[unit:Name()].groundRange
end

function BombardBehaviour:UnitCreated(unit)

end

function BombardBehaviour:Fire()
	if self.target ~= nil then
		EchoDebug("fire")
		local floats = api.vectorFloat()
		-- populate with x, y, z of the position
		floats:push_back(self.target.x)
		floats:push_back(self.target.y)
		floats:push_back(self.target.z)
		self.unit:Internal():ExecuteCustomCommand(CMD_ATTACK, floats)
		self.lastFireFrame = game:Frame()
	end
end

function BombardBehaviour:UnitIdle(unit)
	if self.active then
		local f = game:Frame()
		if self.lastFireFrame == 0 or f > self.lastFireFrame + 300 then
			EchoDebug("idle")
			self:Fire()
		end
	end
end

function BombardBehaviour:Update()
	if self.active then
		local f = game:Frame()
		if self.lastFireFrame == 0 or f > self.lastFireFrame + 900 then
			EchoDebug("retarget")
			local bestCell, valueThreat = ai.targethandler:GetBestBombardCell(self.position, self.range)
			if bestCell ~= nil then
				self.target = bestCell.pos
				if valueThreat > valueThreatThreshold then
					EchoDebug("high priority target: " .. valueThreat)
					self:Fire()
				end
			end
		end
	end
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
