shard_include "common"


BombardBehaviour = class(Behaviour)

local DebugEnabled = false


local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("BombardBehaviour: " .. inStr)
	end
end

local CMD_ATTACK = 20

local valueThreatThreshold = 1600 -- any cell above this level of value+threat will be shot at manually

function BombardBehaviour:Init()
    self.lastFireFrame = 0
    self.lastTargetFrame = 0
    self.targetFrame = 0
    local unit = self.unit:Internal()
    self.position = unit:GetPosition()
    self.range = unitTable[unit:Name()].groundRange
    self.radsPerFrame = 0.015
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

function BombardBehaviour:CeaseFire()
	self.target = nil
	self.unit:Internal():Stop()
end

function BombardBehaviour:UnitIdle(unit)
	if self.active then
		self.idle = true
	end
end

function BombardBehaviour:Update()
	if self.active then
		local f = game:Frame()
		if self.lastTargetFrame == 0 or f > self.lastTargetFrame + 300 then
			EchoDebug("retarget")
			local bestCell, valueThreat, buildingID = ai.targethandler:GetBestBombardCell(self.position, self.range, valueThreatThreshold)
			if bestCell then
				local newTarget
				if buildingID then
					local building = game:GetUnitByID(buildingID)
					if building then
						newTarget = building:GetPosition()
					end
				end
				if not newTarget then newTarget = bestCell.pos end
				if newTarget ~= self.target then
					local newAngle = AngleAtoB(self.position.x, self.position.z, newTarget.x, newTarget.z)
					local ago = f - self.targetFrame
					game:SendToConsole(ago, newAngle, self.targetAngle)
					if self.targetAngle then
						if AngleDist(self.targetAngle, newAngle) > ago * self.radsPerFrame then
							newTarget = nil
						end
					end
					if newTarget then
						self.target = newTarget
						self.targetFrame = f
						self.targetAngle = newAngle
						EchoDebug("new high priority target: " .. valueThreat)
						self:Fire()
					end
				end
			else
				EchoDebug("no target, ceasing manual controlled fire")
				self:CeaseFire()
			end
			self.lastTargetFrame = f
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
