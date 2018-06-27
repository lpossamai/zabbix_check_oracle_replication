#
# zabbix_check_oracle_replication
#

I came across a Standard Oracle DB with no [Data Guard](https://oracle-base.com/articles/11g/data-guard-setup-11gr2). Everything done on the Database (Monitoring) was done via scripting, as on the Standard version the Standby server cannot have the listener running.
Because of that, I had to develop a simple Bash script so I could monitor the replication delay between a Master and a Slave Oracle DB.

__NOTE__: This was done on Oracle 11G Standard Edition

## What we'll be using:
1. Zabbix Server (Make sure you have the Zabbix Agent running)
2. Bash
3. You'll need the `System/sys` Oracle password
4. You'll need SSH access to the Oracle DB you want to monitor

This is how the graph looks like after applying these scripts:
![Replication Delay between a Master and a Slave Oracle DB](https://github.com/lpossamai/zabbix_check_oracle_replication/blob/master/docs/images/db2_archive_log_photo.png)

## How to apply the Replication Monitoring Template for Zabbix
1. Installing the Oracle Client on your Zabbix Server (CentOS 7 in this case)
```
## Files name:
oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
oracle-instantclient11.2-sqlplus-11.2.0.4.0-1.x86_64.rpm

## [Download here](http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html) the files (You'll need an account)
## Installing
yum localinstall oracle-instantclient11.2-* --nogpgcheck
```

2. Creating your environment script for the Oracle Client
```
vim /etc/profile.d/client.sh
export ORACLE_HOME=/usr/lib/oracle/11.2/client64
export PATH=$PATH:$ORACLE_HOME/lib:/usr/sbin:/usr/bin
export ORACLE_SID=testdb
export LD_LIBRARY_PATH=$ORACLE_HOME/lib

```

3. Creating the `check_oracle_replication_master.sh` script:
```
# cd /usr/lib/zabbix/externalscripts/
# vim check_oracle_replication_master

#!/bin/sh
#
# check_replication_master.sh
# This script will check the last applied archiving log on db2
#

# You need to have these paths setup otherwise script won't work.
export ORACLE_HOME=/usr/lib/oracle/11.2/client64
export PATH=$PATH:$ORACLE_HOME/lib:/usr/sbin:/usr/bin
export ORACLE_SID=testdb
export LD_LIBRARY_PATH=$ORACLE_HOME/lib

# Getting the max(sequence) value from v$log_history
COUNT_DB1=$(sqlplus64 sys/syspasswordhere@mydb1 as sysdba @/usr/lib/zabbix/externalscripts/check_replication_db1.sql | awk 'FNR>=14 && FNR<=14')

echo "$COUNT_DB1"

exit
```
