require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("MexUpgradeBehaviour: " .. inStr)
	end
end

MexUpgradeBehaviour = class(Behaviour)

function MexUpgradeBehaviour:Init()
	self.active = false
	self.mohoStarted = false
	self.mexPos = nil
	self.lastFrame = game:Frame()
	EchoDebug("MexUpgradeBehaviour: added to unit "..self.unit:Internal():Name())
end

function MexUpgradeBehaviour:UnitIdle(unit)
	if unit:Internal():ID() == self.unit:Internal():ID() then
		if self:IsActive() then
			EchoDebug("MexUpgradeBehaviour: unit "..self.unit:Internal():Name().." is idle")
			-- maybe we've just finished a moho?
			if self.mohoStarted then
				self.mohoStarted = false
				self.mexPos = nil
			end
			-- maybe we've just finished reclaiming?
			if self.mexPos ~= nil and not self.mohoStarted then
				-- maybe we're ARM and not CORE?
				mohoName = "cormoho"
				tmpType = game:GetTypeByName("armmoho")
				if self.unit:Internal():CanBuild(tmpType) then
					mohoName = "armmoho"
				end
				-- maybe we're underwater?
				tmpType = game:GetTypeByName("comuwmme")
				if self.unit:Internal():CanBuild(tmpType) then
					mohoName = "coruwmme"
				end
				tmpType = game:GetTypeByName("armuwmme")
				if self.unit:Internal():CanBuild(tmpType) then
					mohoName = "armuwmme"
				end
				tmpType = game:GetTypeByName(mohoName)
				-- check if the moho can be built there at all
				local s = map:CanBuildHere(tmpType, self.mexPos)
				if s then
					s = self.unit:Internal():Build(mohoName, self.mexPos)
				end
				if s then
					self.active = true
					self.mohoStarted = true
					self.mexPos = nil
					EchoDebug("MexUpgradeBehaviour: unit "..self.unit:Internal():Name().." starts building a Moho")
				else
					self.mexPos = nil
					self.mohoStarted = false
					self.active = false
					EchoDebug("MexUpgradeBehaviour: unit "..self.unit:Internal():Name().." failed to start building a Moho")
				end
			end

			if not self.mohoStarted and (self.mexPos == nil) then
				EchoDebug("MexUpgradeBehaviour: unit "..self.unit:Internal():Name().." restarts mex upgrade routine")
				StartUpgradeProcess(self)
			end
		end
	end
end

function MexUpgradeBehaviour:Update()
	if not self.active then
		if (self.lastFrame or 0) + 30 < game:Frame() then
			StartUpgradeProcess(self)
		end
	end
end

function MexUpgradeBehaviour:Activate()
	EchoDebug("MexUpgradeBehaviour: active on unit "..self.unit:Internal():Name())
	
	StartUpgradeProcess(self)
end

function MexUpgradeBehaviour:Deactivate()
	self.active = false
	self.mexPos = nil
	self.mohoStarted = false
end

function MexUpgradeBehaviour:Priority()
	if ai.lvl1Mexes > 0 then
		return 101
	else
		return 0
	end
end

function MexUpgradeBehaviour:UnitDamaged(unit,attacker)
end

function StartUpgradeProcess(self)
	-- try to find nearest mex
	local ownUnits = game:GetFriendlies()
	local selfUnit = self.unit:Internal()
	local selfPos = selfUnit:GetPosition()
	local mexUnit = nil
	local closestDistance = 999999
	
	local mexCount = 0
	for _, unit in pairs(ownUnits) do
		local un = unit:Name()	
		if mexUpgrade[un] then
			EchoDebug(un .. " " .. mexUpgrade[un])
			-- make sure you can build the upgrade
			local upgradetype = game:GetTypeByName(mexUpgrade[un])
			if selfUnit:CanBuild(upgradetype) then
				-- make sure you can reach it
				if ai.maphandler:UnitCanGetToUnit(selfUnit, unit) then
					local distMod = 0
					-- if it's not 100% HP, then don't touch it (unless there's REALLY no better choice)
					-- this prevents a situation when engineer reclaims a mex that is still being built by someone else
					if unit:GetHealth() < unit:GetMaxHealth() then
						distMod = distMod + 9000
					end
					local pos = unit:GetPosition()
					-- if there are enemies nearby, don't go there as well
					if ai.targethandler:IsSafePosition(pos, selfUnit) then
						-- if mod number by itself is too high, don't compute the distance at all
						if distMod < closestDistance then
							local dist = distance(pos, selfPos) + distMod
							if dist < closestDistance then
								mexUnit = unit
								closestDistance = dist
							end
						end
					end
				end
			end
			mexCount = mexCount + 1
		end
	end
	ai.lvl1Mexes = mexCount

	local s = false
	if mexUnit ~= nil then
		-- command the engineer to reclaim the mex
		s = self.unit:Internal():Reclaim(mexUnit)
		if s then
			-- we'll build the moho here
			self.mexPos = mexUnit:GetPosition()
		end
	end
	
	if s then
		self.active = true
		EchoDebug("MexUpgradeBehaviour: unit "..self.unit:Internal():Name().." goes to reclaim a mex")
	else
		mexUnit = nil
		self.active = false
		self.lastFrame = game:Frame()
		EchoDebug("MexUpgradeBehaviour: unit "..self.unit:Internal():Name().." failed to start reclaiming")
	end
end