-- Created by Tom J Nowell 2010
-- Shard AI
if ShardSpringLua then
	require "preload/spring_lua/boot"
elseif game_engine then
	require "spring_cpp/boot"
else
	require "preload/shard_null/boot"
end
