
local spGetGameFrame = Spring.GetGameFrame
local spGetProjectileDirection = Spring.GetProjectileDirection

ShardSpringDamage = class(function(a, damage, weaponDefID, paralyzer, projectileID, engineAttacker)
	a.damage = damage
	a.weaponDefID = weaponDefID
	a.paralyzer = paralyzer
	a.projectileID = projectileID
	a.attacker = engineAttacker
	a.gameframe = spGetGameFrame()
	if projectileID then
		local dx, dy, dz = spGetProjectileDirection(projectileID)
		a.direction = {x=dx, y=dy, z=dz}
	end
	a.damageType = weaponDefID
	if weaponDefID then
		local weaponDef = WeaponDefs[weaponDefID]
		if weaponDef then
			a.weaponType = weaponDef.name
		end
	end
end)

function ShardSpringDamage:Damage()
	return self.damage
end

function ShardSpringDamage:Attacker()
	return self.attacker
end

function ShardSpringDamage:Direction()
	return self.direction
end

function ShardSpringDamage:DamageType()
	return self.damageType
end

function ShardSpringDamage:WeaponType()
	return self.weaponType
end
