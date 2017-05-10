-- Created by Tom J Nowell 2010
-- Shard AI
if ShardSpringLua then
	require "preload/spring_lua/boot"
elseif game_engine then
	require "spring_cpp/boot"
else
	require "preload/shard_null/boot"
end

if game_engine then
	shard_include "hooks"
	shard_include "class"
	shard_include "aibase"

	shard_include "preload/spring_cpp/unit"
	shard_include "preload/spring_cpp/unittype"
end