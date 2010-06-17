TaskQueueBehaviour = class(Behaviour)

function TaskQueueBehaviour:Init()
	self.active = false
	u = self.unit
	u = u:Internal()
	self.name = u:Name()
	if self:HasQueues() then
		self.queue = self:GetQueue()
	end
	
end

function TaskQueueBehaviour:HasQueues()
	return (taskqueues[self.name] ~= nil)
end

function TaskQueueBehaviour:UnitBuilt(unit)
	if not self:IsActive() then
		return
	end
	if unit:Internal():ID() == self.unit:Internal():ID() then
		self.progress = true
	end
end

function TaskQueueBehaviour:UnitIdle(unit)
	if not self:IsActive() then
		return
	end
	if unit:Internal():ID() == self.unit:Internal():ID() then
		self.progress = true
		--self.unit:ElectBehaviour()
	end
end

function TaskQueueBehaviour:GetQueue()
	q = taskqueues[self.name]
	if type(q) == "function" then
		--game:SendToConsole("function table found!")
		q = q(self)
	end
	return q
end

function TaskQueueBehaviour:Update()
	if not self:IsActive() then
		return
	end
	local f = game:Frame()
	if math.mod(f,3) == 0 then
		if self.progress == true then
			self:ProgressQueue()
		end
	end
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
		if type(val) == "function" then
			value = val(self)
		end
		utype = game:GetTypeByName(value)
		if utype ~= nil then
			unit = self.unit:Internal()
			if unit:CanBuild(utype) then
				if utype:Extractor() then
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
