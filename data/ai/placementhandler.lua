PlacementHandler = class(Module)

function PlacementHandler:Name()
	return "PlacementHandler"
end

function PlacementHandler:internalName()
	return "placementhandler"
end

function PlacementHandler:Init()
	self.jobs = {}
end

--[[
Usage:

function onSuccess( job, pos )
	-- build something I guess
end
function onFail( job )
	-- nowhere to place it, do something else then?
end
local unittype = ...
local job = {
	start_position=[1,2,3],
	max_radius=500,
	onSuccess=onSuccess,
	onFail=onFail,
	unittype=unittype,
	cleanup_on_unit_death=builderID
}
local success = ai.placementhandler.NewJob( job )
if success then
	-- the job has been schedule, do whatever else we need to do in parallel
	-- when a position has been found, it will call the callback function we passed it
	-- in the future a promise will be returned letting us define what happens
else
	-- there was something wrong with our job and the system rejected it
	-- the programmer should probably check all the values that went into the job were set and valid
end

]]


function PlacementHandler:NewJob( details )
	--[[
	local default = {
		start_position,
		unittype,
		placement_tests: [],
		max_radius=,
		onSuccess=onSuccess,
		onFail=onFail,
		increment=8
		cleanup_on_unit_death
	}
	]]--
	if details["start_position"] == nil then
		return false
	end
	if details["unittype"] == nil then
		return false
	end
	if details["max_radius"] == nil then
		details.max_radius = 1000
	end
	if details["max_radius"] == nil then
		details.max_radius = 1000
	end
	if details["increment"] == nil then
		details.increment = 8
	end
	if details.increment < 8 then
		details.increment = 8
	end
	details.status = 'new'
	details.step = 1

	-- figure out the spiral search pattern necessary 
	local max_width = details.max_radius * 2
	local spiral_width = max_width/details.increment
	details.spiral = self:GenerateSpiral(spiral_width, spiral_width )

	table.insert( self.jobs, details )

	-- for now it's using a completion handler, which is a function
	-- passed along that it will call when it's finished, but tbh I'd
	-- prefer to return some sort of promise structure
	return true
end


function PlacementHandler:Update()
	--[[

	We need to run through our jobs, but we also need to make sure of several things:

	 - when a placement job finishes, we stop processing until the next frame
	 - that each job only gets a limited amount of time to run
	 - that the algorithm can run bit by bit over several frames

	To this end, each iteration of the search is self contained. This way we can
	progress 5 or 6 steps along the algorithm for each job, making sure we don't
	spend too long searching and lag the game out.

	As a bonus, this opens up the future for scheduling and collaborative searches.
	It also allows us to cancel and pause searches.

	For our situation, we're going to allot a time budget for each job, and a
	time budget for each frame. During this time, we can only work on a job for
	so long. If it's a fast CPU we can do more iterations in that time. It also
	means we can only work on so many jobs per frame. This way we get the top
	of the queue done sooner, so we don't get bogged down in an ever growing queue.

	A bonus of this, is that quick jobs will finish earlier, allowing work to be
	done on an extra job. Another side of this is that if the cpu is busy with
	stuff, we might have to finish early. I envisage Shard should take time
	measurements for the entire frame to make sure that modules such as this
	one can give themselves smaller budgets when under load
	]]

	-- exit early if there are no jobs
	if #self.jobs == 0 then
		return
	end

	self:RunIterations()
	self:CleanupJobs()
end

function PlacementHandler:RunIterations()
	for i,j in ipairs(self.jobs) do
		if j.status ~= 'cleanup' then
			local job = self.jobs[i]
			self:RunJobIterations( job )
		end
	end
end

function PlacementHandler:RunJobIterations( job )
	local stillGotTime = 20
	-- given this particular job, lets give it a time budget and do as many
	-- iterations as we can
	while ( stillGotTime > 0 ) and ( job.status ~= 'cleanup' ) do
		self:IterateJob( job )
		stillGotTime = stillGotTime - 1
	end
end

function PlacementHandler:IterateJob( job )
	-- setup this run
	job.status = 'running'
	local step = job.step
	local spos = job.spiral[step]
	local pos = { x=0,y=0,z=0}
	pos.x = spos.x * job.increment
	pos.y = spos.y * job.increment
	pos.z = 0

	-- test this particular step of the spiral
	local buildable = self.ai.map:CanBuildHere(job.unittype, pos )
	if buildable then
		-- we found a place!
		job.result = pos
		job.status = 'cleanup'
		job.onSuccess( job, pos )
	end

	job.step = job.step + 1
	if job.step > #job.spiral then
		-- we reached the end of the search pattern, we failed to
		-- find a location, tell the requested and end the job
		job.onFail( job )
		job.status = 'cleanup'
		job.result = false
	end
end

function PlacementHandler:CleanupJobs()
	-- try and clean up dead recruits where possible
	while true do
		for i,j in ipairs(self.jobs) do
			if j.status == 'cleanup' then
				table.remove(self.jobs,i)
				break
			end
		end
	end
end

--[[
Some jobs are tied to units being alive. This could be because
it's the building the job was intended for. Eitherway, if that
unit dies then the associated job is unnecessary, and needs to
be cleaned up to save cpu
]]
function PlacementHandler:UnitDead(engineunit)
	for i,j in ipairs(self.jobs) do
		if j['cleanup_on_unit_death'] ~= nil then
			if j.cleanup_on_unit_death == engineunit:ID() then
				j.status = 'cleanup'
			end
		end
	end
end


function PlacementHandler:GenerateSpiral( width, height)
	local x = 0
	local y = 0
	local dx = 0
	local dy = -1
	local t = math.max(width,height)
	local maxI = t*t;
	local result = {}
	for i=0, maxI do
		if  ((-width/2 <= x) and (x <= width/2) and (-height/2 <= y) and (y <= height/2)) then
			table.insert( result, {x,y} )
		end
		if ( ( x == y ) or ( ( x < 0 ) and ( x == -y ) ) or ( (x > 0) and ( x == 1-y ) ) ) then
			t = dx
			dx = dy * -1
			dy = t
		end
		x = x + dx
		y = y + dy
	end
	return result
end