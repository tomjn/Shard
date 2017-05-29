CommonHandler = class(Module)

function CommonHandler:Name()
	return "CommonHandler"
end

function CommonHandler:internalName()
	return "commonhandler"
end

function CommonHandler:Init()
	shard_include "unitlists"
	if ShardSpringLua then
		if not unitTable or not featureTable then
			unitTable, featureTable = shard_include("getunitfeaturetable")
		end
		if not CommonFunctionsLoaded then
			shard_include "commonfunctions"
		end
		if not UnitListsLoaded then
			shard_include "unitlists"
		end
	else
		shard_include("unittable-" .. self.ai.game:GameName())
		shard_include("featuretable-" .. self.ai.game:GameName())
		shard_include "commonfunctions"
	end
end