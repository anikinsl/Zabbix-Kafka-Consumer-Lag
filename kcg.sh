#!/bin/bash
###
# Version  Date      Author    Description
#-----------------------------------------------
# 0.1      22/02/18  Shini31   Initial version
# 1.0      17.08.21  anikinsl  Remove most unused code
#
###

#Global Variables
VERSION="0.1"
PROGNAME=`basename $0`
PROGPATH=`dirname $0`
KAFKA_CG_PATH="/opt/kafka/bin"
KAFKA_HOST="127.0.0.1"
KAFKA_PORT="9092"
CG=""

#Help function
print_help() {
  echo "This zabbix script can discovery all consumer groups in a Kafka server and calculate the global lag for a specific consumer group"
  echo "Usage: $PROGNAME"
  echo "    -h (--host)      <host>  Hostname or IP address of Kafka server"
  echo "    -p (--port)      <port>  Port of Kafka server"
  echo "    -g (--group)     <consumer_group> Name of the consumer group for lag"
  echo "    -d (--discovery) List all the consumer group for zabbix discovery"
  echo "    -v (--version)   Script version"
  echo "    --help           Script usage"
}

#Check presence of required parameter's number
if [ "$#" -lt 1 ]; then
  echo "PROGNAME: requires at least one parameters"
  print_help
  exit 1
fi

#Getting Parameters options
OPTS=$(getopt -o g:h:p:dghlv -l host:,port:,discovery,group:,help,lag,version -n "$(basename $0)" -- "$@")
eval set -- "$OPTS"
while true
do
  case $1 in
    -h|--host)
      KAFKA_HOST="$2"
      shift 2
      ;;
    -p|--port)
      KAFKA_PORT="$2"
      shift 2
      ;;
    -g|--group)
      CG="$2"
      shift 2
      ;;
    -d|--discovery)
      CG_DISCOVERY="true"
      shift
      ;;
    --help)
      print_help
      exit 0
      ;;
    -v|--version)
      print_version
      exit 0
      ;;
    --)
      shift ; break
      ;;
    *)
      echo "Unknown argument: $1"
      print_help
      exit 1
      ;;
  esac
done


# Zabbix's discovery

if [ "$CG_DISCOVERY" ]; then
  CG_LIST=`${KAFKA_CG_PATH}/kafka-consumer-groups.sh --bootstrap-server ${KAFKA_HOST}:${KAFKA_PORT} --list 2>/dev/null`
  ZBX_DISCO_LIST=`for i in ${CG_LIST}; do echo -en "{"; echo -en "\"{#CONSUMER_GROUP}\":\"$i\""; echo -en "},"; done`
  ZBX_DISCO_LIST=${ZBX_DISCO_LIST%?};
  echo -e "{\"data\":[${ZBX_DISCO_LIST}]}"

elif [ "$CG" == "" ]; then
  echo "Consumer group (-g) must to be declare."
  exit 1

else
  ${KAFKA_CG_PATH}/kafka-consumer-groups.sh --bootstrap-server ${KAFKA_HOST}:${KAFKA_PORT} --describe --group ${CG} 2>/dev/null | tail -n +3 | awk '{ sum += $5 } END { print sum }'

fi
