require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("AssistHandler: " .. inStr)
	end
end

AssistHandler = class(Module)

function AssistHandler:Name()
	return "AssistHandler"
end

function AssistHandler:internalName()
	return "assisthandler"
end

function AssistHandler:Init()
	self.free = {}
	self.working = {}
	self.totalAssignments = 0
	self.magnets = {}
end

-- checks whether the assistant can help the builder
function AssistHandler:IsLocal(asstbehaviour, builder)
	local bpos = builder:GetPosition()
	local aunit = asstbehaviour.unit:Internal()
	local apos = aunit:GetPosition()
	local dist = distance(bpos, apos)
	local okay = true
	if not ai.maphandler:UnitCanGoHere(aunit, bpos) then
		okay = false
	end
	local uname = aunit:Name()
	if okay and (uname == "cornanotc" or uname == "armnanotc") then
		if dist > 390 then
			okay = false
		end
	end
	if okay then
		return dist
	else
		return false
	end
end

-- tries to get a certain number of assistants to help a builder
-- if there aren't enough available, returns false
function AssistHandler:Summon(builder, number, force, gentle)
	if number == nil or number == 0 then number = #self.free end
	if not force then EchoDebug("not forced") end
	EchoDebug(#self.free .. " assistants free")
	if #self.free < number then 
		-- EchoDebug("total assignments: " .. self.totalAssignments)
		EchoDebug("less than " .. number .. " assistants free")
		if not force then return false end
	end
	local bid = builder:ID()
	if #self.free >= number or (force and #self.free > 0) then
		-- get the closest ones first
		-- order by distance
		local bydistance = {}
		local count = 0
		while #self.free > 0 do
			local asstbehaviour = table.remove(self.free)
			local skip = false
			if asstbehaviour.unit == nil then
				skip = true
			elseif asstbehaviour.unit:Internal() == nil then
				skip = true
			end
			if not skip then
				local dist = self:IsLocal(asstbehaviour, builder)
				if dist then
					bydistance[dist] = asstbehaviour
					count = count + 1
				end
			end
		end
		if count < number and not force then return false end
		if count == 0 and force then
			return 0
		end
		-- summon in order of distance
		local n = 0
		if self.working[bid] == nil then
			self.totalAssignments = self.totalAssignments + 1
			self.working[bid] = {}
		end
		for dist, asstbehaviour in pairsByKeys(bydistance) do
			if n >= number then
				-- add any unused back into free
				table.insert(self.free, asstbehaviour)
			else
				table.insert(self.working[bid], asstbehaviour)
				asstbehaviour:Assign(builder)
				n = n + 1
			end
		end
		EchoDebug(n .. " assistants summoned to " .. bid .. "now " .. #self.free .. " assistants free")
		if n > 0 then
			return n
		elseif force then
			return 0
		end
	end
	if force then
		return 0
	else
		return false
	end
end

-- assistants that become free before this magnet is released will get assigned to this builder
function AssistHandler:Magnetize(builder, number)
	if number == nil or number == 0 then number = -1 end
	table.insert(self.magnets, {bid = builder:ID(), builder = builder, pos = builder:GetPosition(), number = number})
end

-- summons and magnetizes until released
function AssistHandler:PersistantSummon(builder, maxNumber, minNumber)
	if minNumber == nil then minNumber = 0 end
	if maxNumber == 0 then
		-- get every free assistant until it's done building
		local hashelp = self:Summon(builder, 0, true)
		if hashelp >= minNumber then
			self:Magnetize(builder)
			return hashelp
		end
	else
		-- get enough assistants
		local hashelp = self:Summon(builder, maxNumber, true)
		if hashelp >= minNumber then
			if hashelp < maxNumber then
				self:Magnetize(builder, maxNumber - hashelp)
			end
			return hashelp
		end
	end
	return false
end

-- assigns any free assistants (but keeps them free for summoning or magnetism)
function AssistHandler:TakeUpSlack(builder)
	if #self.free == 0 then return end
	self:DoMagnets()
	if #self.free == 0 then return end
	for i, asstbehaviour in pairs(self.free) do
		local skip = false
		if asstbehaviour.unit == nil then
			table.remove(self.free, i)
			skip = true
		elseif asstbehaviour.unit:Internal() == nil then
			table.remove(self.free, i)
			skip = true
		end
		if not skip then
			if self:IsLocal(asstbehaviour, builder) then
				asstbehaviour:Assign(builder)
			end
		end
	end
end

-- assign any free assistants to really important ongoing projects
function AssistHandler:DoMagnets()
	for fi, asstbehaviour in pairs(self.free) do
		if #self.magnets == 0 then break end
		local skip = false
		if asstbehaviour.unit == nil then
			table.remove(self.free, fi)
			skip = true
		elseif asstbehaviour.unit:Internal() == nil then
			table.remove(self.free, fi)
			skip = true
		end
		if not skip then
			local aunit = asstbehaviour.unit:Internal()
			local apos = aunit:GetPosition()
			local bestDist = 10000
			local best
			for mi, magnet in pairs(self.magnets) do
				local dist = self:IsLocal(asstbehaviour, magnet.builder)
				if dist then
					if dist < bestDist then
						bestDist = dist
						best = mi
					end
				end
			end
			if best then
				local magnet = self.magnets[best]
				if self.working[magnet.bid] == nil then
					self.working[magnet.bid] = {}
					self.totalAssignments = self.totalAssignments + 1
				end
				table.insert(self.working[magnet.bid], asstbehaviour)
				asstbehaviour:Assign(magnet.builder)
				table.remove(self.free, fi)
				if magnet.number ~= -1 then magnet.number = magnet.number - 1 end
				EchoDebug("one assistant magnetted to " .. magnet.bid .. " magnet has " .. magnet.number .. " left to get from " .. #self.free .. " available")
				if magnet.number == 0 then
					table.remove(self.magnets, 1)
				end
			end
		end
	end
end

-- returns any assistants assigned to a builder to being available
function AssistHandler:Release(builder, bid, dead)
	if bid == nil then 
		bid = builder:ID()
	end
	if self.working[bid] == nil then return false end
	if #self.working[bid] == 0 then
		self.working[bid] = nil
		return false
	end
	EchoDebug("releasing " .. #self.working[bid] .. " from " .. bid)
	while #self.working[bid] > 0 do
		local asstbehaviour = table.remove(self.working[bid])
		if dead then asstbehaviour:Assign(nil) end
		table.insert(self.free, asstbehaviour)
		EchoDebug(asstbehaviour.name .. " released to available assistants")
	end
	self.working[bid] = nil
	self.totalAssignments = self.totalAssignments - 1
	EchoDebug("demagnetizing " .. bid)
	for i, magnet in pairs(self.magnets) do
		if magnet.bid == bid then
			EchoDebug("removing a magnet")
			magnet.builder = nil
			table.remove(self.magnets, i)
		end
	end
	-- EchoDebug("resetting magnets...")
	self:DoMagnets()
	-- EchoDebug("magnets reset")
	return true
end

function AssistHandler:IsFree(asstbehaviour)
	for i, ab in pairs(self.free) do
		if ab == asstbehaviour then return true end
	end
	return false
end

function AssistHandler:AddFree(asstbehaviour)
	if not self:IsFree(asstbehaviour) then
		table.insert(self.free, asstbehaviour)
		EchoDebug(asstbehaviour.name .. " added to available assistants")
	end
	self:DoMagnets()
end

function AssistHandler:RemoveFree(asstbehaviour)
	for i, ab in pairs(self.free) do
		if ab == asstbehaviour then
			table.remove(self.free, i)
			EchoDebug(asstbehaviour.name .. " removed from available assistants")
			return true
		end
	end
	return false
end

function AssistHandler:RemoveWorking(asstbehaviour)
	if asstbehaviour.target == nil then return false end
	local targetID = asstbehaviour.target:ID()
	for bid, workers in pairs(self.working) do
		if bid == targetID then
			for i, ab in pairs(workers) do
				if ab == asstbehaviour then
					table.remove(workers, i)
					if #workers == 0 then
						self.working[bid] = nil
						self.totalAssignments = self.totalAssignments - 1
					end
					EchoDebug(asstbehaviour.name .. " removed from working assistants")
					return true
				end
			end
		end
	end
	return false
end