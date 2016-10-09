shard_include "unitlists"
if ShardSpringLua then
	unitTable, featureTable = shard_include("getunitfeaturetable")
else
	shard_include("unittable-" .. game:GameName())
	shard_include("featuretable-" .. game:GameName())
end
shard_include "commonfunctions"