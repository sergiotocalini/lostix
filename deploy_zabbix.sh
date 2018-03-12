#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

LOGSTASH_SERVER=${1:-localhost}
LOGSTASH_PORT=${2:-9022}
LOGSTASH_METHOD=${3:-http}
LOGSTASH_URL="${LOGSTASH_METHOD}://${LOGSTASH_SERVER}:${LOGSTASH_PORT}"

mkdir -p ${ZABBIX_DIR}/scripts/agentd/lostix
cp ${SOURCE_DIR}/lostix/lostix.conf.example ${ZABBIX_DIR}/scripts/agentd/lostix/lostix.conf
cp ${SOURCE_DIR}/lostix/lostix.sh ${ZABBIX_DIR}/scripts/agentd/lostix/
cp ${SOURCE_DIR}/lostix/zabbix_agentd.conf ${ZABBIX_DIR}/zabbix_agentd.d/lostix.conf
sed -i "s|LOGSTASH_URL=.*|LOGSTASH_URL=\"${LOGSTASH_URL}\"|g" ${ZABBIX_DIR}/scripts/agentd/lostix/lostix.conf
