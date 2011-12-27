AttackHandler = class(Module)

function AttackHandler:Name()
	return "AttackHandler"
end

function AttackHandler:internalName()
	return "attackhandler"
end

function AttackHandler:Init()
	self.recruits = {}
	self.counter = 8
end

function AttackHandler:Update()
	local f = game:Frame()
	if math.mod(f,6) == 0 then
		self:DoTargetting()
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

function AttackHandler:UnitDead(engineunit)
	if engineunit:Team() == game:GetTeamID() then
		self.counter = self.counter - 0.05
		self.counter = math.max(self.counter,5)
	end
end


function AttackHandler:UnitIdle(engineunit)
	--
end

function AttackHandler:DoTargetting()
	if #self.recruits > self.counter then
		-- find somewhere to attack
		local cells = {}
		local celllist = {}
		local mapdimensions = game.map:MapDimensions()
		--enemies = game:GetEnemies()
		local enemies = game:GetEnemies()

		if #enemies > 0 then
			-- figure out where all the enemies are!
			for i=1,#enemies do
				local e = enemies[i]

				if e ~= nil then
					pos = e:GetPosition()
					px = pos.x - math.fmod(pos.x,600)
					pz = pos.z - math.fmod(pos.z,600)
					px = px/600
					pz = pz/600
					if cells[px] == nil then
						cells[px] = {}
					end
					if cells[px][pz] == nil then
						local newcell = { count = 0, posx = 0,posz=0,}
						cells[px][pz] = newcell
						table.insert(celllist,newcell)
					end
					cell = cells[px][pz]
					cell.count = cell.count + 1
					
					-- we dont want to target the center of the cell encase its a ledge with nothing
					-- on it etc so target this units position instead
					cell.posx = pos.x
					cell.posz = pos.z
				end

			end
			
			local bestCell = nil
			-- now find the smallest nonvacant cell to go lynch!
			for i=1,#celllist do
				local cell = celllist[i]
				if bestCell == nil then
					bestCell = cell
				else
					if cell.count < bestCell.count then
						bestCell = cell
					end
				end
			end
			
			-- if we have a cell then lets go attack it!
			if bestCell ~= nil then
				for i,recruit in ipairs(self.recruits) do
					recruit:AttackCell(bestCell)
				end
				
				self.counter = self.counter + 0.2
				
				-- remove all our recruits!
				self.recruits = {}
			end
		end
		
		-- cleanup
		cellist = nil
		cells = nil
		mapdimensions = nil
		
	end
end

function AttackHandler:IsRecruit(attkbehaviour)
	for i,v in ipairs(self.recruits) do
		if v == attkbehaviour then
			return true
		end
	end
	return false
end

function AttackHandler:AddRecruit(attkbehaviour)
	if not self:IsRecruit(attkbehaviour) then
		table.insert(self.recruits,attkbehaviour)
	end
end

function AttackHandler:RemoveRecruit(attkbehaviour)
	for i,v in ipairs(self.recruits) do
		if v == attkbehaviour then
			table.remove(self.recruits,i)
			return true
		end
	end
	return false
end
