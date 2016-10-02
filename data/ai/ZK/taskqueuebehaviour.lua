TaskQueueBehaviour = class(Behaviour)

function TaskQueueBehaviour:Init()
	self.active = false
	u = self.unit
	u = u:Internal()
	self.name = u:Name()
	self.countdown = 0
	if self:HasQueues() then
		self.queue = self:GetQueue()
	end
	
	self.waiting = {}
	local CMD_FIRE_STATE = 45
	local CMD_MOVE_STATE = 50
	local CMD_RETREAT = 34223
	
	local floats = api.vectorFloat()
	floats:push_back(2)
	u:ExecuteCustomCommand(CMD_MOVE_STATE, floats)
	u:ExecuteCustomCommand(CMD_FIRE_STATE, floats)
	u:ExecuteCustomCommand(CMD_RETREAT, floats)
	
end

function TaskQueueBehaviour:HasQueues()
	return (taskqueues[self.name] ~= nil)
end

function TaskQueueBehaviour:OwnerBuilt()
	if not self:IsActive() then
		return
	end
	self.progress = true
end

function TaskQueueBehaviour:OwnerIdle()
	if not self:IsActive() then
		return
	end
	self.progress = true
	self.countdown = 0
	--self.unit:ElectBehaviour()
end

function TaskQueueBehaviour:OwnerMoveFailed()
	if not self:IsActive() then
		return
	end
	self:OwnerIdle()
end

function TaskQueueBehaviour:OwnerDead()
	if self.waiting ~= nil then
		for k,v in pairs(self.waiting) do
			ai.modules.sleep.Kill(self.waiting[k])
		end
	end
	self.waiting = nil
	self.unit = nil
end

function TaskQueueBehaviour:GetQueue()
	q = taskqueues[self.name]
	if type(q) == "function" then
		q = q(self)
	end
	return q
end

function TaskQueueBehaviour:Update()
	if not self:IsActive() then
		return
	end
	local f = game:Frame()
	local s = self.countdown
	if self.progress == true then
	--if math.mod(f,3) == 0 then
		if (ai.tqblastframe ~= f) or (ai.tqblastframe == nil) or (self.countdown == 15) then
			self.countdown = 0
			ai.tqblastframe = f
			self:ProgressQueue()
		else
			if self.countdown == nil then
				self.countdown = 1
			else
				self.countdown = self.countdown + 1
			end
		end
	end
end
TaskQueueWakeup = class(function(a,tqb)
	a.tqb = tqb
end)
function TaskQueueWakeup:wakeup()
	game:sendtoconsole("advancing queue from sleep1")
	self.tqb:ProgressQueue()
end
function TaskQueueBehaviour:ProgressQueue()
	self.progress = false
	if self.queue ~= nil then
		local idx, val = next(self.queue,self.idx)
		self.idx = idx
		if idx == nil then
			self.queue = self:GetQueue(name)
			self.progress = true
			return
		end
		
		local utype = nil
		local value = val
		if type(val) == "table" then
			local action = value.action
			if action == "wait" then
				t = TaskQueueWakeup(self)
				tqb = self
				ai.sleep:Wait({ wakeup = function() tqb:ProgressQueue() end, },value.frames)
				return
			end
		else
			if type(val) == "function" then
				value = val(self)
			end
			if utype ~= "next" then
				utype = game:GetTypeByName(value)
				if utype ~= nil then
					unit = self.unit:Internal()
					if unit:CanBuild(utype) then
						if value == "cormex" then
							-- find a free spot!
							
							p = unit:GetPosition()
							p = ai.metalspothandler:ClosestFreeSpot(utype,p)
							if p ~= nil then
								success = self.unit:Internal():Build(utype,p)
								self.progress = not success
							else
								self.progress = true
							end
						else
							self.progress = not self.unit:Internal():Build(utype)
						end
					else
						self.progress = true
					end
				else
					game:SendToConsole("Cannot build:"..value..", couldnt grab the unit type from the engine")
					self.progress = true
				end
			else
				self.progress = true
			end
		end
	end
end

function TaskQueueBehaviour:Activate()
	self.progress = true
	self.active = true
end

function TaskQueueBehaviour:Deactivate()
	self.active = false
end

function TaskQueueBehaviour:Priority()
	return 50
end
