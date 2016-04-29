-- Created by Tom J Nowell 2010
-- Shard AI
if ShardSpringLua then
	function shard_include( file )
		if type(file) ~= 'string' then
			return nil
		end
		local gameFile = "luarules/gadgets/ai/" ..  Game.gameShortName .. "/" .. file .. ".lua"
		local baseFile = "luarules/gadgets/ai/" .. file .. ".lua"
		local preloadFile = "luarules/gadgets/ai/preload/" .. file .. ".lua"
		if VFS.FileExists(gameFile) then
			-- Spring.Echo("got gameFile", gameFile)
			return VFS.Include(gameFile)
		elseif VFS.FileExists(baseFile) then
			-- Spring.Echo("got baseFile", baseFile)
			return VFS.Include(baseFile)
		elseif VFS.FileExists(preloadFile) then
			-- Spring.Echo("got preloadFile", preloadFile)
			return VFS.Include(preloadFile)
		end
	end
else
	function shard_include( file )
		if type(file) ~= 'string' then
			return nil
		end
		local ok, mod = pcall( require, game_engine:GameName().."/"..file )
		if ok then
			return mod
		else
			require( file )
		end
	end
end

shard_include "hooks"
shard_include "class"
shard_include "aibase"

if ShardSpringLua then
	shard_include "spring_lua/unit"
	shard_include "spring_lua/unittype"
	shard_include "spring_lua/damage"
	shard_include "spring_lua/feature"
else
	shard_include "spring_native/unit"
	shard_include "spring_lua/unittype"
end