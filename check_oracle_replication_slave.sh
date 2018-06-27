#!/bin/sh
#
# check_replication_slave.sh
# This script will check the last applied archiving log on db2.datacentre.motorweb.co.nz
#

# You need to have these paths setup otherwise script won't work.
export ORACLE_HOME=/usr/lib/oracle/11.2/client64
export PATH=$PATH:$ORACLE_HOME/lib:/usr/sbin:/usr/bin
export ORACLE_SID=testdb
export LD_LIBRARY_PATH=$ORACLE_HOME/lib

# Getting the max(sequence) value from v$log_history
COUNT_DB2=$(sqlplus64 sys/syspasswordhere@mydb2 as sysdba @/usr/lib/zabbix/externalscripts/check_replication_db2.sql | awk 'FNR>=14 && FNR<=14')

echo "$COUNT_DB2"
exit
