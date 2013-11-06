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
	self.magnets = {}
end

-- tries to get a certain number of assistants to help a builder
-- if there aren't enough available, returns false
function AssistHandler:Summon(builder, number, force)
	if number == nil or number == 0 then number = #self.free end
	if #self.free < number then 
		-- if there aren't any assistants at all, build the thing anyway
		if #self.working == 0 then return true end
		if not force then return false end
	end
	local bid = builder:ID()
	if #self.free >= number or (force and #self.free > 0) then
		-- get the closest ones first
		local bpos = builder:GetPosition()
		-- order by distance
		local bydistance = {}
		local count = 0
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
					bydistance[dist] = i
					count = count + 1
				end
			end
		end
		if count < number and not force then return false end
		-- summon in order of distance
		local summoned = {}
		local n = 0
		if self.working[bid] == nil then self.working[bid] = {} end
		for dist, i in pairsByKeys(bydistance) do
			local asstbehaviour = self.free[i]
			table.insert(self.working[bid], asstbehaviour)
			asstbehaviour:Assign(builder)
			table.insert(summoned, i)
			n = n + 1
			if n == number then break end
		end
		-- remove those summoned from those free
		bydistance = {}
		for nothing, i in pairs(summoned) do
			table.remove(self.free, i)
		end
		return true
	end
	if force then
		return true
	else
		return false
	end
end

function AssistHandler:Magnetize(builder, number)
	if number == nil or number == 0 then number = 99 end
	table.insert(self.magnets, {bid = builder:ID(), builder = builder, pos = builder:GetPosition(), number = number})
	self:DoMagnets()
end

-- assign any free assistants to really important ongoing projects
function AssistHandler:DoMagnets()
	for i, asstbehaviour in pairs(self.free) do
		local skip = false
		if asstbehaviour.unit == nil then
			table.remove(self.free, i)
			skip = true
		elseif asstbehaviour.unit:Internal() == nil then
			table.remove(self.free, i)
			skip = true
		end
		if #self.magnets == 0 then
			break
		elseif not skip then
			local aunit = asstbehaviour.unit:Internal()
			local apos = aunit:GetPosition()
			local bestDist = 10000
			local best
			for i, magnet in pairs(self.magnets) do
				local dist = distance(apos, magnet.pos)
				if dist < bestDist and ai.maphandler:UnitCanGoHere(aunit, magnet.pos) then
					bestDist = dist
					best = i
				end
			end
			if best then
				local magnet = self.magnets[best]
				if self.working[magnet.bid] == nil then self.working[magnet.bid] = {} end
				table.insert(self.working[magnet.bid], asstbehaviour)
				asstbehaviour:Assign(magnet.builder)
				table.remove(self.free, i)
				magnet.number = magnet.number - 1
				if magnet.number == 0 then
					table.remove(self.magnets, 1)
				end
			end
		end
	end
end

-- returns any assistants assigned to a builder to being available
function AssistHandler:Release(builder, bid, dead, doNotDemagnetsize)
	if bid == nil then 
		bid = builder:ID()
	end
	if self.working[bid] == nil then return false end
	EchoDebug("releasing " .. #self.working[bid] .. " from " .. bid)
	while #self.working[bid] > 0 do
		local asstbehaviour = table.remove(self.working[bid])
		if dead == true then asstbehaviour:Assign(nil) end
		table.insert(self.free, asstbehaviour)
	end
	self.working[bid] = nil
	if doNotDemagnetsize and not dead then
		-- ignore
	else
		EchoDebug("demagnetizing " .. bid)
		for i, magnet in pairs(self.magnets) do
			if magnet.bid == bid then
				EchoDebug("removing a magnet")
				magnet.builder = nil
				table.remove(self.magnets, i)
			end
		end
		EchoDebug("resetting magnets...")
		self:DoMagnets()
		EchoDebug("magnets reset")
	end
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