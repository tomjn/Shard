shard_include "common"

local DebugEnabled = false


local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("CleanHandler: " .. inStr)
	end
end

CleanHandler = class(Module)

function CleanHandler:Name()
	return "CleanHandler"
end

function CleanHandler:internalName()
	return "cleanhandler"
end

function CleanHandler:Init()
	self.cleanables = {}
	self.bigEnergyCount = 0
end

function CleanHandler:UnitBuilt(unit)
	if unit:Team() == self.ai.id then
		if self:IsCleanable(unit) then
			EchoDebug("cleanable " .. unit:Name())
			self.cleanables[#self.cleanables+1] = unit
		elseif self:IsBigEnergy(unit) then
			EchoDebug("big energy " .. unit:Name())
			self.bigEnergyCount = self.bigEnergyCount + 1
		end
	end
end

function CleanHandler:UnitDestroyed(unit)
	if unit:Team() == self.ai.id then
		self:RemoveCleanable(unit:ID())
	end
end

function CleanHandler:RemoveCleanable(unitID)
	for i = #self.cleanables, 1, -1 do
		local cleanable = self.cleanables[i]
		if cleanable:ID() == unitID then
			EchoDebug("remove cleanable " .. cleanable:Name())
			table.remove(self.cleanables, i)
			return
		end
	end
end

function CleanHandler:IsCleanable(unit)
	return cleanable[unit:Name()]
end

function CleanHandler:IsBigEnergy(unit)
	local ut = unitTable[unit:Name()]
	if ut then
		return (ut.totalEnergyOut > 750)
	end
end

function CleanHandler:GetCleanables()
	if self.ai.Metal.full > 0.9 or self.bigEnergyCount < 2 then
		return
	end
	return self.cleanables
end

function CleanHandler:ClosestCleanable(unit)
	local cleanables = self.ai.cleanhandler:GetCleanables()
	if not cleanables or #cleanables == 0 then
		return
	end
	local myPos = unit:GetPosition()
	local bestDist, bestCleanable
	for i = #cleanables, 1, -1 do
		local cleanable = cleanables[i]
		local p = cleanable:GetPosition()
		if p then
			local dist = Distance(myPos, p)
			if not bestDist or dist < bestDist then
				bestCleanable = cleanable
				bestDist = dist
			end
		else
			self:RemoveCleanable(cleanable:ID())
		end
	end
	return bestCleanable
end