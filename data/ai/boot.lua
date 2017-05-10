-- @TODO: Move top level logic out of ai.lua into here, and then make it load environment specific boot.lua files

if ShardSpringLua then
	require "preload/spring_lua/boot"
elseif game_engine then
	require "spring_cpp/boot"
else
	require "preload/shard_null/boot"
end

require( "ai" )

-- create and use an AI
if ShardSpringLua then
	return AI()
else
	ai = AI()
end
