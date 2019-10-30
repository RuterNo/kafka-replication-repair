# Replication Repair
## Description
Simple bash script to automatically set the replication factor to 3 for all topics, as the recommended by Apache. 

https://kafka.apache.org/22/documentation/streams/developer-guide/config-streams

## Requirements

These commands must be available from your bash terminal:

- [topicmappr](https://github.com/DataDog/kafka-kit)
- kafka-topics
- kafka-reassign-partitions
- awk

## Supported actions

### Verify replication configs
See if there are any topics with replication different from 3
```
./replication_repair.sh -z 127.0.0.1:2181 verify
```

### Generate replication configs
Generate replication configurations for all topics with replication different from 3
```
./replication_repair.sh -z 127.0.0.1:2181 -f output_folder generate
```

### Apply replication configurations to topics
Apply all replication configurations found in folder X

```
./replication_repair.sh -z 127.0.0.1:2181 -f output_folder execute
```

## Known issues 

```
There is an existing assignment running.
```
You can only do a limited amount of replication re-configuring at the same time, otherwise the operation will be aborted. 
This script does not try to handle this situation in any way. 

**Work-around:** Re-generate configurations and run the execute step again to resolve
