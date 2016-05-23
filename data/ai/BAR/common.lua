shard_include "unitlists"
if ShardSpringLua then
	unitTable, featureTable = shard_include "getunitfeaturetable"
else
	shard_include "unittable"
	shard_include "featuretable"
end
shard_include "commonfunctions"