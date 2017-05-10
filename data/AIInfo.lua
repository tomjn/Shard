--
--  Info Definition Table format
--
--
--  These keywords must be lowercase for LuaParser to read them.
--
--  key:      user defined or one of the SKIRMISH_AI_PROPERTY_* defines in
--            SSkirmishAILibrary.h
--  value:    the value of the property
--  desc:     the description (could be used as a tooltip)
--
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local infos = {
	{
		key    = 'shortName',
		value  = 'Shard',
		desc   = 'machine conform name.',
	},
	{
		key    = 'version',
		value  = 'dev', -- AI version - !This comment is used for parsing!
	},
	{
		key    = 'name',
		value  = 'Shard Native',
		desc   = 'human readable name.',
	},
	{
		key    = 'description',
		value  = 'Shard by AF, C++ Lua AI, works with ZK,CA,KP,BA,CT, and The Cursed',
		desc   = 'this should help noobs to find out whether this AI is what they want',
	},
	{
		key    = 'url',
		value  = 'https://shard.tomjn.com',
		desc   = 'URL with more detailed info about the AI',
	},
	{
		key    = 'loadSupported',
		value  = 'no',
		desc   = 'whether this AI supports loading or not',
	},
	{
		key    = 'interfaceShortName',
		value  = 'C', -- AI Interface name - !This comment is used for parsing!
		desc   = 'the shortName of the AI interface this AI needs',
	},
	{
		key    = 'interfaceVersion',
		value  = '0.1', -- AI Interface version - !This comment is used for parsing!
		desc   = 'the minimum version of the AI interface this AI needs',
	},
	{
		key    = 'supportedGames',
		value  = 'BA,KP.n,KP,The Cursed,ZK,ca,ct',
		desc   = 'list of games supported, comma separated',
	},
}

return infos
