#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo ""
    echo "Options:"
    echo "  -F            Force configuration overwrite."
    echo "  -H            Displays this help message."
    echo "  -P            Installation prefix (SCRIPT_DIR)."
    echo "  -Z            Zabbix agent include files directory (ZABBIX_INC)."
    echo "  -u            Configuration key LOGSTASH_URL."
    echo ""
    echo "Please send any bug reports to https://github.com/sergiotocalini/lostix/issues"
    exit 1
}

while getopts ":o:p:u:P:Z:FH" OPTION; do
    case ${OPTION} in
	F)
	    FORCE=true
	    ;;
	H)
	    usage
	    ;;
	P)
	    SCRIPT_DIR="${OPTARG}"
	    if [[ ! "${SCRIPT_DIR}" =~ .*lostix ]]; then
		     SCRIPT_DIR="${SCRIPT_DIR}/lostix"
	    fi
	    ;;
	Z)
	    ZABBIX_INC="${OPTARG}"
	    ;;
	u)
	    LOGSTASH_URL="${OPTARG}"
	    ;;
	\?)
	    exit 1
	    ;;
    esac
done

[ -n "${SCRIPT_DIR}"  ] || SCRIPT_DIR="${ZABBIX_DIR}/scripts/agentd/lostix"
[ -n "${ZABBIX_INC}"  ] || ZABBIX_INC="${ZABBIX_DIR}/zabbix_agentd.d"
[ -n "${LOGSTASH_URL}" ] || LIBVIRT_URI="http://localhost:9600"

# Creating necessary directories
mkdir -p "${SCRIPT_DIR}" "${ZABBIX_INC}" 2>/dev/null

# Copying the main script and dependencies
cp -rpv  "${SOURCE_DIR}/lostix/lostix.sh"          "${SCRIPT_DIR}/lostix.sh"

# Provisioning script configuration
SCRIPT_CFG="${SCRIPT_DIR}/lostix.conf"
cp -rpv "${SOURCE_DIR}/lostix/lostix.conf.example" "${SCRIPT_CFG}.new"

# Adding script configuration values
regex_cfg[0]="s|LOGSTASH_URL=.*|LOGSTASH_URL=\"${LOGSTASH_URL}\"|g"
for index in ${!regex_cfg[*]}; do
    sed -i'' -e "${regex_cfg[${index}]}" "${SCRIPT_CFG}.new"
done

# Checking if the new configuration exist
if [[ -f "${SCRIPT_CFG}" && ${FORCE:-false} == false ]]; then
    state=$(cmp --silent "${SCRIPT_CFG}" "${SCRIPT_CFG}.new")
    if [[ ${?} == 0 ]]; then
	rm "${SCRIPT_CFG}.new" 2>/dev/null
    fi
else
    mv "${SCRIPT_CFG}.new" "${SCRIPT_CFG}" 2>/dev/null
fi

# Provisioning zabbix_agent configuration
SCRIPT_ZBX="${ZABBIX_INC}/lostix.conf"
cp -rpv "${SOURCE_DIR}/lostix/zabbix_agentd.conf"  "${SCRIPT_ZBX}.new"
regex_inc[0]="s|{PREFIX}|${SCRIPT_DIR}|g"
for index in ${!regex_inc[*]}; do
    sed -i'' -e "${regex_inc[${index}]}" "${SCRIPT_ZBX}.new"
done
if [[ -f "${SCRIPT_ZBX}" ]]; then
    state=$(cmp --silent "${SCRIPT_ZBX}" "${SCRIPT_ZBX}.new")
    if [[ ${?} == 0 ]]; then
	rm "${SCRIPT_ZBX}.new" 2>/dev/null
    fi
else
    mv "${SCRIPT_ZBX}.new" "${SCRIPT_ZBX}" 2>/dev/null
fi
