-- An initial boot behaviour that takes over a unit initially,
-- makes it wait 3-4 seconds idle after it's been built, then
-- releases control
--
-- This helps prevent units in factories from immediatley building
-- things or doing stuff before they've left the factory and
-- blocking the factory from building the next unit

BootBehaviour = class(Behaviour, behaviourSetup)

function BootBehaviour:Init()
	self.waiting = true
	self.canmove = self:Owner():CanMove()
	self.finished = false
	self.count = 150
end

function BootBehaviour:OwnerBuilt()
	self.finished = true
end

function BootBehaviour:Update()
	if self.waiting == false then
		return
	end
	if self.finished then
		self.count = self.count - 1
		if self.count < 1 then
			self.waiting = false
			self.unit:ElectBehaviour()
		end
	end
end

function BootBehaviour:Priority()
	-- don't apply to starting units
	if self.game:Frame() < 10 then
		return 0
	end

	-- don't apply to structures
	if self.canmove == false then
		return 0
	end
	if self.waiting then
		return 500
	else
		return 0
	end
end

-- set to hold position while being repaired after resurrect
function BootBehaviour:SetMoveState()
	self:Owner():HoldPosition()
end
