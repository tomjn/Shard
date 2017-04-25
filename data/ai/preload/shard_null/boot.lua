

function shard_include( file )
	if type(file) ~= 'string' then
		return nil
	end
	require( file )
end

local null_api={}

-- UnsyncedRead

	function null_api:IsUnitAllied(unit_id)
		return Spring.IsUnitAllied(unit_id)
	end
return null_api