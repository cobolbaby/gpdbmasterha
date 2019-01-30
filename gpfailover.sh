#!/bin/bash
# 如何设置了`set -e`，那只要出现异常服务就宕掉
# set -e

echo "Check Time: `date`"

GPMDW=mdw
GPSMDW=smdw
MASTER_DATA_DIRECTORY=/disk1/gpdata/gpmaster/gpseg-1

# 判断节点是否可达
pingCheck(){
    # Ref: https://www.thegeekstuff.com/2009/11/ping-tutorial-13-effective-ping-command-examples/
    PING_CHECK=`ping -c 4 -w 6 $1 | grep ", 0% packet loss" | wc -l`
    if [ $PING_CHECK -ne 1 ]; then
        echo "Conldn't ping gpdb $1 node"
        return 1
    fi
    return 0
}

# 服务检测
psqlCheck(){
    timeout 60 ssh gpadmin@$1 "source /usr/local/greenplum-db/greenplum_path.sh ; psql -U gpadmin -d ICTDB -c 'select count(1) from public.do_not_delete_master_status;'"
    if [ $? -ne 0 ]; then
        # psql: FATAL:  the database system is starting up -- Standby服务没启动
        # psql: FATAL:  DTM initialization: failure during startup recovery, retry failed, check segment status (cdbtm.c:1605) -- Master宕掉之后暂未恢复
        # psql: FATAL:  System was started in master-only utility mode - only utility mode connections are allowed -- Master脱离了整个集群
        echo "Greenplum $1 node gone away"
        return 2
    fi
    return 0
}

switchStandby(){
    timeout 120 ssh gpadmin@${GPSMDW} "source /usr/local/greenplum-db/greenplum_path.sh; export MASTER_DATA_DIRECTORY=${MASTER_DATA_DIRECTORY}; export PGPORT=5432; gpactivatestandby -a -d ${MASTER_DATA_DIRECTORY}"
    if [ $? -ne 0 ]; then
        # gpactivatestandby:smdw:gpadmin-[CRITICAL]:-PGPORT environment variable not set
        echo "Failed to gpactivatestandby"
        return 5
    fi
    return 0
}

checkStandby(){
    STANDBY_STATE=`timeout 60 ssh gpadmin@${GPMDW} "source /usr/local/greenplum-db/greenplum_path.sh; export MASTER_DATA_DIRECTORY=${MASTER_DATA_DIRECTORY}; gpstate -f" | grep "Standby host passive" | wc -l`
    if [ $STANDBY_STATE -ne 1 ]; then
        echo "Standby master instance not active"
        return 3
    fi
    return 0
}

checkStandbySwitch(){
    MASTER_STATE=`timeout 60 ssh gpadmin@${GPSMDW} "source /usr/local/greenplum-db/greenplum_path.sh; export MASTER_DATA_DIRECTORY=${MASTER_DATA_DIRECTORY}; gpstate -b" | grep "Master instance\s*=\s*Active" | wc -l`
    if [ $MASTER_STATE -ne 1 ]; then
        echo "Standby master instance failed to switch"
        return 4
    fi
    return 0
}

# 判断是否存在已有进程
NO_OF_PROCESS=`ps -ef | grep gpfailover.sh | grep -v "grep" | wc -l`
if [ $NO_OF_PROCESS -gt 2 ]; then
    echo "failover process hang up..."
    exit
fi

if (pingCheck ${GPMDW} && psqlCheck ${GPMDW}); then
    checkStandby || echo "No active standby node"
    exit
fi

pingCheck ${GPSMDW} || exit
psqlCheck ${GPSMDW} || (switchStandby && checkStandbySwitch) || exit