#!/bin/bash
set -e

echo "【`date`】"

# 远程执行指令
MASTER_DATA_DIRECTORY=/disk1/gpdata/gpmaster/gpseg-1

# 判断主机联通性

# mdw ping测试



ssh gpadmin@mdw "source /usr/local/greenplum-db/greenplum_path.sh ; psql -U gpadmin -d postgres -c 'ANALYZE;'"
ssh gpadmin@mdw "source /usr/local/greenplum-db/greenplum_path.sh ; export MASTER_DATA_DIRECTORY=${MASTER_DATA_DIRECTORY}; gpstate -f"
ssh gpadmin@smdw "source /usr/local/greenplum-db/greenplum_path.sh ; gpactivatestandby -d ${MASTER_DATA_DIRECTORY}"
ssh gpadmin@smdw "source /usr/local/greenplum-db/greenplum_path.sh; export MASTER_DATA_DIRECTORY=${MASTER_DATA_DIRECTORY}; gpstate -f"
ssh gpadmin@smdw "source /usr/local/greenplum-db/greenplum_path.sh ; psql -U gpadmin -d postgres -c 'ANALYZE;'"