#!/bin/bash
set -e

echo "【`date`】"

GPMDW=mdw
GPSMDW=smdw
MASTER_DATA_DIRECTORY=/disk1/gpdata/gpmaster/gpseg-1

## killing previous gpfailover daemon
NO_OF_PROCESS=`ps -ef | grep gpfailover.sh | grep -v "grep" | wc -l`
if [ $NO_OF_PROCESS -gt 1 ]; then
    echo "gpfailover is running"
    exit
fi

# 判断主机联通性
PING_CHECK=`ping -c 4 ${GPSMDW} | grep "0% packet loss" | wc -l`
if [ $PING_CHECK -eq 0 ]; then
    exit 2
fi

# 远程执行指令
MASTER_STATE=`ssh gpadmin@mdw "source /usr/local/greenplum-db/greenplum_path.sh ; psql -U gpadmin -d postgres -c 'ANALYZE;'"`
if [ $MASTER_STATE == "ANALYZE" ]; then 
    exit 3
fi

STANDBY_STATE=`ssh gpadmin@mdw "source /usr/local/greenplum-db/greenplum_path.sh ; export MASTER_DATA_DIRECTORY=${MASTER_DATA_DIRECTORY}; gpstate -f" | grep "no entry" | wc -l`
if [ $STANDBY_STATE -eq 0 ]; then 
    exit 4
fi

exit

ssh gpadmin@smdw "source /usr/local/greenplum-db/greenplum_path.sh ; gpactivatestandby -d ${MASTER_DATA_DIRECTORY}"
ssh gpadmin@smdw "source /usr/local/greenplum-db/greenplum_path.sh; export MASTER_DATA_DIRECTORY=${MASTER_DATA_DIRECTORY}; gpstate -f"
ssh gpadmin@smdw "source /usr/local/greenplum-db/greenplum_path.sh ; psql -U gpadmin -d postgres -c 'ANALYZE;'"

