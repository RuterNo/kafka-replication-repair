#!/bin/bash

verify() {
  echo "Connecting to zookeeper: $zookeeper"
  echo "Verifying replication settings."
  i=0
  for topicname in $(kafka-topics --zookeeper $zookeeper --list); do
    for invalid_topic in $(kafka-topics --zookeeper $zookeeper --describe --topic "$topicname" | awk '/ReplicationFactor:/ && !/ReplicationFactor:3/' | awk --field-separator=" " '{printf $1 "_________________" $3}'); do
      echo "$invalid_topic"
      i=$((i + 1))
    done
  done
  echo "Number of topics with invalid replication factor: $i"
}

generate() {
  echo "Connecting to zookeeper: $zookeeper"
  echo "Generating replication config files to folder: $folder"

  # Creating folder if not exist
  [ ! -d "$folder" ] && mkdir "$folder"

  i=0
  for topicname in $(kafka-topics --zookeeper $zookeeper --list); do
    for incorrect_topic in $(kafka-topics --zookeeper $zookeeper --describe --topic "$topicname" | awk '/ReplicationFactor:/ && !/ReplicationFactor:3/' | awk --field-separator=" " '{print $1}' | awk --field-separator=":" '{print $2}'); do
      topicmappr rebuild --topics "$incorrect_topic" --replication 3 --brokers -1 --zk-addr $zookeeper --out-path $folder
      i=$((i + 1))
    done
  done
  echo "Created replication config files found in: $folder"
}

execute() {
  echo "Connecting to zookeeper: $zookeeper"
  echo "Modifying topic replications based on files found in folder: $folder* "

  for file in "$folder"*
  do
      if [[ -f $file ]]; then
        topic_file=$(echo "$file" | awk --field-separator "/" '{print $NF}')
        topic_name=$(echo "$topic_file" | awk --field-separator "." '{print $1}')
        echo "Found topic file: $topic_file"
        echo "Will apply it to topic: $topic_name"
        kafka-reassign-partitions --zookeeper "$zookeeper" --reassignment-json-file "$file" --execute
        sleep 20
      fi
  done
}

#########################
# The command line help #
#########################
display_help() {
  echo "Usage: $0 [option...] {verify|generate|execute}" >&2
  echo
  echo "   -z, --zookeeper           specify the zookeeper node to connect to"
  echo "   -f, --folder              the folder where the configuration files will be generated to / read from"
  echo
  exit 1
}

###########################
# Defining default values #
###########################
zookeeper="localhost:2181"
folder="replication_configs/"

################################
# Check if parameters options  #
# are given on the commandline #
################################
while :; do
  case "$1" in
  -z | --zookeeper)
    if [ $# -ne 0 ]; then
      zookeeper="$2" # You may want to check validity of $2
    fi
    shift 2
    ;;
  -h | --help)
    display_help # Call your function
    exit 0
    ;;
  -f | --folder)
    folder="$2"
    shift 2
    ;;
  --) # End of all options
    shift
    break
    ;;
  -*)
    echo "Error: Unknown option: $1" >&2
    ## or call function display_help
    exit 1
    ;;
  *) # No more options
    break
    ;;
  esac
done

######################
# Check if parameter #
# is set too execute #
######################
case "$1" in
verify)
  verify # calling function verify()
  ;;
generate)
  generate # calling function generate()
  ;;
execute)
  execute # calling function execute()
  ;;
*)

  display_help

  exit 1
  ;;
esac
