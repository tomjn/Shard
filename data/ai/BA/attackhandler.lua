require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("AttackHandler: " .. inStr)
	end
end

local fmod = math.fmod
local floor = math.floor
local ceil = math.ceil
local mod = math.mod

local congregateDistanceMinimum = 75
local congregateDistancePerMember = 30

AttackHandler = class(Module)

function AttackHandler:Name()
	return "AttackHandler"
end

function AttackHandler:internalName()
	return "attackhandler"
end

function AttackHandler:Init()
	self.recruits = {}
	self.squads = {}
	self.counter = {}
	self.totalThreat = {}
	ai.hasAttacked = 0
	ai.couldAttack = 0
end

function AttackHandler:Update()
	local f = game:Frame()
	if mod(f, 300) == 0 then
		self:ReTarget()
	end
	if mod(f, 150) == 0 then
		self:DraftSquads()
	end
	if mod(f, 60) == 0 then
		self:DoMovement()
	end
end

function AttackHandler:GameEnd()
	--
end

function AttackHandler:UnitCreated(engineunit)
	--
end

function AttackHandler:UnitBuilt(engineunit)
	--
end

function AttackHandler:UnitIdle(engineunit)
	--
end

function AttackHandler:DraftSquads()
	local needtarget = {}
	-- find which mtypes need targets
	for mtype, recruits in pairs(self.recruits) do
		if #recruits >= self.counter[mtype] then
			table.insert(needtarget, mtype)
		end
	end
	for nothing, mtype in pairs(needtarget) do
		-- prepare a squad
		local squad = { members = {}, notarget = 0, congregating = false }
		local representative
		for _, attkbehaviour in pairs(self.recruits[mtype]) do
			if attkbehaviour ~= nil then
				if attkbehaviour.unit ~= nil then
					if representative == nil then representative = attkbehaviour.unit:Internal() end
					table.insert(squad.members, attkbehaviour)
				end
			end
		end
		if representative ~= nil then
			ai.couldAttack = ai.couldAttack + 1
			-- don't actually draft the squad unless there's something to attack
			local bestCell = ai.targethandler:GetBestAttackCell(representative)
			if bestCell ~= nil then
				squad.target = bestCell.pos
				table.insert(self.squads, squad)
				-- clear recruits
				self.recruits[mtype] = {}
				ai.hasAttacked = ai.hasAttacked + 1
			end
		end
	end
end

function AttackHandler:ReTarget()
	for is, squad in pairs(self.squads) do
		local representative
		for iu, member in pairs(squad.members) do
			if member ~= nil then
				if member.unit ~= nil then
					representative = member.unit:Internal()
					if representative ~= nil then
						break
					end
				end
			end
		end
		if representative == nil then
			table.remove(self.squads, is)
		else
			-- find a target
			local bestCell = ai.targethandler:GetBestAttackCell(representative)
			if bestCell == nil then
				squad.notarget = squad.notarget + 1
				if squad.target == nil or squad.notarget > 3 then
					-- if no target found initially, or no target for the last three targetting checks, disassemble and recruit the squad
					for iu, member in pairs(squad.members) do
						self:AddRecruit(member)
					end
					table.remove(self.squads, is)
				end
			else
				squad.target = bestCell.pos
				squad.notarget = 0
			end
		end
	end
end

function AttackHandler:DoMovement()
	for is, squad in pairs(self.squads) do
		-- get a representative and midpoint
		local representative
		local totalx = 0
		local totalz = 0
		for iu, member in pairs(squad.members) do
			local unit
			if member ~= nil then
				if member.unit ~= nil then
					unit = member.unit:Internal()
				end
			end
			if unit ~= nil then
				if representative == nil then representative = unit end
				local tmpPos = unit:GetPosition()
				totalx = totalx + tmpPos.x
				totalz = totalz + tmpPos.z
			else 
				table.remove(squad.members, iu)
			end
		end

		if #squad.members == 0 then
			table.remove(self.squads, is)
		else
			-- determine distances from midpoint
			local midPos = api.Position()
			midPos.x = totalx / #squad.members
			midPos.z = totalz / #squad.members
			midPos.y = 0
			local congDist = math.max(#squad.members * congregateDistancePerMember, congregateDistanceMinimum)
			local stragglers = 0
			for iu, member in pairs(squad.members) do
				local unit = member.unit:Internal()
				local upos = unit:GetPosition()
				local cdist = quickdistance(upos, midPos)
				if cdist > congDist then
					if member.straggler == nil then
						member.straggler = 1
					else
						member.straggler = member.straggler + 1
					end
					if member.straggler > 22 then
						-- remove from squad if the unit is taking longer than 45 seconds
						EchoDebug("leaving slowpoke behind")
						self:AddRecruit(member)
						table.remove(squad.members, iu)
					else
						stragglers = stragglers + 1
					end
					if member.lastDist ~= nil then
						if cdist > member.lastDist - 2 and cdist < member.lastDist + 2 then
							if member.stuck == nil then
								member.stuck = 1
							else
								member.stuck = member.stuck + 1
							end
							if member.stuck > 3 then
								-- remove from squad if the unit is pathfinder-stuck
								EchoDebug("leaving stuck behind")
								self:AddRecruit(member)
								table.remove(squad.members, iu)
							end
						else
							member.stuck = 0
						end
					end
				else
					member.straggler = 0
				end
				member.lastDist = cdist
			end
			local congregate = false
			EchoDebug("attack squad of " .. #squad.members .. " members, " .. stragglers .. " stragglers")
			if stragglers >= math.ceil(#squad.members * 0.1) then
				congregate = true
			end
			-- attack or congregate
			if congregate then
				if not squad.congregating then
					-- congregate squad
					squad.congregating = true
					for iu, member in pairs(squad.members) do
						local ordered = member:Congregate(midPos)
						if not ordered and squad.congregating then squad.congregating = false end
					end
				end
				squad.attacking = nil
			else
				if squad.attacking ~= squad.target then
					-- squad attacks if that wasn't the last order
					if squad.target ~= nil then
						for iu, member in pairs(squad.members) do
							member:Attack(squad.target)
						end
						squad.attacking = squad.target
					end
				end
				squad.congregating = false
			end
		end
	end
end

function AttackHandler:IsMember(attkbehaviour)
	if attkbehaviour == nil then return false end
	for is, squad in pairs(self.squads) do
		for iu, member in pairs(squad.members) do
			if member == attkbehaviour then return true end
		end
	end
	return false
end

function AttackHandler:RemoveMember(attkbehaviour)
	if attkbehaviour == nil then return false end
	local found = false
	for is, squad in pairs(self.squads) do
		for iu, member in pairs(squad.members) do
			if member == attkbehaviour then
				table.remove(squad.members, iu)
				found = true
				break
			end
		end
		if found then
			if #squad.members == 0 then 
				table.remove(self.squads, is)
			end
			break
		end
	end
	if found then return true end
	return false
end

function AttackHandler:IsRecruit(attkbehaviour)
	if attkbehaviour.unit == nil then return false end
	local mtype = ai.maphandler:MobilityOfUnit(attkbehaviour.unit:Internal())
	if self.recruits[mtype] ~= nil then
		for i,v in pairs(self.recruits[mtype]) do
			if v == attkbehaviour then
				return true
			end
		end
	end
	return false
end

function AttackHandler:AddRecruit(attkbehaviour)
	if not self:IsRecruit(attkbehaviour) then
		if attkbehaviour.unit ~= nil then
			-- EchoDebug("adding attack recruit")
			local mtype = ai.maphandler:MobilityOfUnit(attkbehaviour.unit:Internal())
			if self.recruits[mtype] == nil then self.recruits[mtype] = {} end
			if self.counter[mtype] == nil then self.counter[mtype] = baseAttackCounter end
			if self.totalThreat[mtype] == nil then self.totalThreat[mtype] = 0 end
			self.totalThreat[mtype] = self.totalThreat[mtype] + UnitThreat(attkbehaviour.unit:Internal():Name())
			table.insert(self.recruits[mtype], attkbehaviour)
			attkbehaviour:SetMoveState()
			attkbehaviour:Free()
		else
			EchoDebug("unit is nil!")
		end
	end
end

function AttackHandler:RemoveRecruit(attkbehaviour)
	for mtype, recruits in pairs(self.recruits) do
		for i,v in ipairs(recruits) do
			if v == attkbehaviour then
				self.totalThreat[mtype] = self.totalThreat[mtype] - UnitThreat(attkbehaviour.unit:Internal():Name())
				table.remove(self.recruits[mtype], i)
				return true
			end
		end
	end
	return false
end

function AttackHandler:NeedMore(attkbehaviour)
	local mtype = attkbehaviour.mtype
	self.counter[mtype] = self.counter[mtype] + 0.5
	EchoDebug(mtype .. " attack counter: " .. self.counter[mtype])
end

function AttackHandler:NeedLess(mtype)
	if mtype == nil then
		for mtype, count in pairs(self.counter) do
			if self.counter[mtype] == nil then self.counter[mtype] = baseAttackCounter end
			self.counter[mtype] = self.counter[mtype] - 0.25
			self.counter[mtype] = math.max(self.counter[mtype], minAttackCounter)
			EchoDebug(mtype .. " attack counter: " .. self.counter[mtype])
		end
	else
		if self.counter[mtype] == nil then self.counter[mtype] = baseAttackCounter end
		self.counter[mtype] = self.counter[mtype] - 0.25
		self.counter[mtype] = math.max(self.counter[mtype], minAttackCounter)
		EchoDebug(mtype .. " attack counter: " .. self.counter[mtype])
	end
end

function AttackHandler:GetCounter(mtype)
	if mtype == nil then
		local highestCounter = 0
		for mtype, counter in pairs(self.counter) do
			if counter > highestCounter then highestCounter = counter end
		end
		return highestCounter
	end
	if self.counter[mtype] == nil then
		return baseAttackCounter
	else
		return self.counter[mtype]
	end
end