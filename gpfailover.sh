#!/bin/bash
#set -e

echo "【`date`】"

GPMDW=mdw
GPSMDW=smdw
MASTER_DATA_DIRECTORY=/disk1/gpdata/gpmaster/gpseg-1

# 判断节点是否可达
pingCheck(){
    PING_CHECK=`ping -c 4 $1 | grep ", 0% packet loss" | wc -l`
    if [ $PING_CHECK -ne 1 ]; then
        echo "Conldn't ping gpdb $1 node"
        return 1
    fi
    return 0
}

psqlCheck(){
    SERVICE_CHECK=`ssh gpadmin@$1 "source /usr/local/greenplum-db/greenplum_path.sh ; psql -U gpadmin -d postgres -c 'ANALYZE;'"`
    if [ $SERVICE_CHECK != "ANALYZE" ]; then
        echo "Greenplum service gone away"
        return 2
    fi
    return 0
}

switchStandby(){
    # gpactivatestandby:smdw:gpadmin-[CRITICAL]:-PGPORT environment variable not set
    ssh gpadmin@${GPSMDW} "source /usr/local/greenplum-db/greenplum_path.sh; export MASTER_DATA_DIRECTORY=${MASTER_DATA_DIRECTORY}; export PGPORT=5432; gpactivatestandby -a -d ${MASTER_DATA_DIRECTORY}"
    if [ $? -ne 0 ]; then
        echo "Failed to gpactivatestandby"
        return 5
    fi
    return 0
}

checkStandby(){
    STANDBY_STATE=`ssh gpadmin@${GPMDW} "source /usr/local/greenplum-db/greenplum_path.sh; export MASTER_DATA_DIRECTORY=${MASTER_DATA_DIRECTORY}; gpstate -f" | grep "Standby host passive" | wc -l`
    if [ $STANDBY_STATE -ne 1 ]; then
        echo "Standby master instance not active"
        return 3
    fi
    return 0
}

checkStandbySwitch(){
    MASTER_STATE=`ssh gpadmin@${GPSMDW} "source /usr/local/greenplum-db/greenplum_path.sh; export MASTER_DATA_DIRECTORY=${MASTER_DATA_DIRECTORY}; gpstate -b" | grep "Master instance\s*=\s*Active" | wc -l`
    if [ $MASTER_STATE -ne 1 ]; then
        echo "Standby master instance failed to switch"
        return 4
    fi
    return 0
}

# 判断是否存在已有进程
NO_OF_PROCESS=`ps -ef | grep gpfailover.sh | grep -v "grep" | wc -l`
if [ $NO_OF_PROCESS -gt 2 ]; then
    exit 0
fi

if (pingCheck ${GPMDW} && psqlCheck ${GPMDW}) then
    checkStandby || echo "No active standby node"
    exit 0
fi

pingCheck ${GPSMDW} || exit 1
psqlCheck ${GPSMDW} || (switchStandby && checkStandbySwitch) || exit 4

exit 0

# ping: mdw: Name or service not known
# Conldn't ping gpdb mdw node
# psql: FATAL:  the database system is starting up
# ./gpfailover.sh: line 22: [: !=: unary operator expected
# gpfailover exit code: 0
