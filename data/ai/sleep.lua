Sleep = class(Module)

function Sleep:Name()
	return "Sleep"
end

function Sleep:internalName()
	return "sleep"
end

function Sleep:Init()
	self.sleeping = {}
end

function Sleep:Update()
	local done = {}
	local count = 0
	for k,v in pairs(self.sleeping) do
		if (v-1) < 1 then
			-- limit the number of things woken up each frame to 50
			if #done < 50 then
				self:Wakeup(k)
				table.insert(done,k)
			end
		end
		self.sleeping[k] = v -1
	end
	for i=1,#done do
		self:Kill(done[i])
	end
	count = nil
	done = nil
end

-- Pass in a function to be called in the future,
-- and how many frames to wait. Note that if the AI is busy,
-- there may be minor delays of several frames
function Sleep:Wait(functor, frames)
	if functor == nil then
		game:SendToConsole("error: functor == nil in Sleep:Wait ")
	else
		self.sleeping[functor] = frames
	end
end

function Sleep:Wakeup(key)
	if key == nil then
		game:SendToConsole("key == nil in Sleep:Wakeup()")
	else
		if type(key) == "table" then
			if key.wakeup ~= nil then
				key:wakeup()
			else
				game:SendToConsole("key:wakeup == nil in Sleep:Wakeup")
			end
		else
			key()
		end
	end
end

function Sleep:Kill(key)
	self.sleeping[key] = nil
end
