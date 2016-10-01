-- initial setup of things

function shard_include( file )
	if type(file) ~= 'string' then
		return nil
	end
	local ok1, mod1 = pcall( require, game_engine:GameName().."/"..file )
	if ok1 then
		return mod1
	else
		local ok2, mod2 = pcall( require, file )
		if ok2 then
			return mod2
		else
			game_engine:SendToConsole("require can't load " .. game_engine:GameName().."/"..file .. " error: " .. mod1)
			game_engine:SendToConsole("require can't load " .. file .. " error: " .. mod2)
		end
	end
end
