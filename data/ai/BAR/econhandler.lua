shard_include "common"

local DebugEnabled = false


local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("EconHandler: " .. inStr)
	end
end

EconHandler = class(Module)

function EconHandler:Name()
	return "EconHandler"
end

function EconHandler:internalName()
	return "econhandler"
end

function EconHandler:Init()
	self.resourceNames = { "Energy", "Metal" }
	self.lastFrame = -17 -- so that it updates immediately even on the first frame
	self.hasData = false -- so that it gets data immediately
	self.samples = {}
	ai.Energy = {}
	ai.Metal = {}
	self:Update()
end

function EconHandler:Update()
	local f = game:Frame()
	if f > self.lastFrame + 15 then
		local sample = {}
		-- because resource data is stored as userdata
		for i, name in pairs(self.resourceNames) do
			local udata = game:GetResourceByName(name)
			sample[name] = { income = udata.income, usage = udata.usage, reserves = udata.reserves, capacity = udata.capacity }
		end
		table.insert(self.samples, sample)
		if not self.hasData or #self.samples == 6 then self:Average() end
		self.lastFrame = f
	end
end

function EconHandler:Average()
	local reset = false
	for i, sample in pairs(self.samples) do
		for name, resource in pairs(sample) do
			for property, value in pairs(resource) do
				if not reset then ai[name][property] = 0 end
				ai[name][property] = ai[name][property] + value
			end
		end
		if not reset then reset = true end
	end
	local totalSamples = #self.samples
	for name, resource in pairs(self.samples[1]) do
		for property, value in pairs(resource) do
			ai[name][property] = ai[name][property] / totalSamples
		end
		ai[name].extra = ai[name].income - ai[name].usage
		if ai[name].capacity == 0 then
			ai[name].full = math.inf
		else
			ai[name].full = ai[name].reserves / ai[name].capacity
		end
		if ai[name].income == 0 then
			ai[name].tics = math.inf
		else
			ai[name].tics = ai[name].reserves / ai[name].income
		end
	end
	if not self.hasData then self.hasData = true end
	self.samples = {}
	self:DebugAll()
end

function EconHandler:DebugAll()
	if DebugEnabled then
		for i, name in pairs(self.resourceNames) do
			local resource = ai[name]
			for property, value in pairs(resource) do
				EchoDebug(name .. "." .. property .. ": " .. value)
			end
		end
	end
end

