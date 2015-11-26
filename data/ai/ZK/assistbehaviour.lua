-- require "taskqueues"
require "commonfunctions"

nanoTurretList = {
	armnanotc = 1,
}

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("AssistBehaviour: " .. inStr)
	end
end

local CMD_GUARD = 25
local CMD_PATROL = 15

AssistBehaviour = class(Behaviour)

function AssistBehaviour:DoIAssist()
	if self.isNanoTurret then
		return true
	else
		return false
	end
end

function AssistBehaviour:Init()
	local uname = self.unit:Internal():Name()
	self.name = uname
	if nanoTurretList[uname] then self.isNanoTurret = true end
end

function AssistBehaviour:UnitBuilt(unit)
	if unit.engineID == self.unit.engineID then
		if self.isNanoTurret then
			-- set nano turrets to patrol
			local upos = RandomAway(self.unit:Internal():GetPosition(), 50)
			local floats = api.vectorFloat()
			-- populate with x, y, z of the position
			self.havenPos = upos
			floats:push_back(upos.x)
			floats:push_back(upos.y)
			floats:push_back(upos.z)
			self.unit:Internal():ExecuteCustomCommand(CMD_PATROL, floats)
			game:SendToContent("sethaven|"..upos.x..'|'..upos.y..'|'..upos.z);
		end
	end
end

function AttackerBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		if(self.havenPos) then
			local upos = self.havenPos
			game:SendToContent("sethaven|"..upos.x..'|'..upos.y..'|'..upos.z);
		end
	end
end
