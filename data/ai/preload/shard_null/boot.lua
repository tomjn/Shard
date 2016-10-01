

function shard_include( file )
	if type(file) ~= 'string' then
		return nil
	end
	require( file )
end