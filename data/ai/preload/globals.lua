-- Created by Tom J Nowell 2010
-- Shard AI
if ShardSpringLua then
	require "preload/spring_lua/boot"
elseif game_engine then
	require "spring_native/boot"
else
	require "preload/shard_null/boot"
end


if ShardSpringLua then
	require "preload/hooks"
	require "preload/class"
	require "preload/aibase"
	require "preload/spring_lua/unit"
	require "preload/spring_lua/unittype"
	require "preload/spring_lua/damage"
	require "preload/spring_lua/feature"
	require "preload/spring_lua/controlpoint"
elseif game_engine then
	shard_include "hooks"
	shard_include "class"
	shard_include "aibase"

	shard_include "preload/spring_native/unit"
	shard_include "preload/spring_native/unittype"
else
	-- load null objects
	require "preload/hooks"
	require "preload/class"
	require "preload/aibase"
end