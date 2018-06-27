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
5. An account (it is free) at http://www.oracle.com

This is how the graph looks like after applying these scripts:
![Replication Delay between a Master and a Slave Oracle DB](https://github.com/lpossamai/zabbix_check_oracle_replication/blob/master/docs/images/db2_archive_log_photo.png)

## Setting up the scripts, Oracle Listener and required files
1. Installing the Oracle Client on your Zabbix Server (CentOS 7 in this case)

You can [download the latest files here](http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html)

```
## Files names are:
oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
oracle-instantclient11.2-sqlplus-11.2.0.4.0-1.x86_64.rpm

## Installing it
yum localinstall oracle-instantclient11.2-* --nogpgcheck
```

2. Setting up your `tnsnames.ora` file
```
#vim $ORACLE_HOME/network/admin/tnsnames.ora

MYDB1 =
  (DESCRIPTION =
    (ADDRESS_LIST =
     (ADDRESS=(PROTOCOL=TCP)(HOST=192.168.1.1)(PORT=1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = testdb)
    )
  )

MYDB2 =
  (DESCRIPTION =
    (ADDRESS_LIST =
     (ADDRESS=(PROTOCOL=TCP)(HOST=192.168.1.2)(PORT=1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = testdb)
    )
  )


```

3. Creating your environment script for the Oracle Client
```
vim /etc/profile.d/client.sh
export ORACLE_HOME=/usr/lib/oracle/11.2/client64
export PATH=$PATH:$ORACLE_HOME/lib:/usr/sbin:/usr/bin
export ORACLE_SID=testdb
export LD_LIBRARY_PATH=$ORACLE_HOME/lib

```

4. Creating the `check_oracle_replication_master.sh` script:

```
# cd /usr/lib/zabbix/externalscripts/
# vim check_oracle_replication_master.sh

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

5. Creating the `check_oracle_replication_slave.sh` script:

```
# cd /usr/lib/zabbix/externalscripts/
# vim check_oracle_replication_slave.sh

#!/bin/sh
#
# check_replication_slave.sh
# This script will check the last applied archiving log on db2
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

```

6. Download the files [check_replication_db1.sql](https://github.com/lpossamai/zabbix_check_oracle_replication/blob/master/check_replication_db1.sql) and [check_replication_db2.sql](https://github.com/lpossamai/zabbix_check_oracle_replication/blob/master/check_replication_db2.sql).
7. Put the files in `/usr/lib/zabbix/externalscripts`
8. Applying permissions to the files
```
cd /usr/lib/zabbix/externalscripts/
chown zabbix:zabbix *
chmod +x check_oracle_replication_slave.sh check_oracle_replication_master.sh

```

9. Test the scripts by running them: `./check_oracle_replication_master.sh`
![The output should look like](https://github.com/lpossamai/zabbix_check_oracle_replication/blob/master/docs/images/db1_run_script.png)

## Setting up the Zabbix part
1. Create a new template: `CONFIGURATION > TEMPLATES > CREATE TEMPLATE`
```
Template name: Template Oracle Standby DB
Groups: Templates/Databases
```

2. Create a new application called `oracle`
3. In Items, create a new Item `Primary archived log sequence`:
```
Name: Primary archived log sequence
Type: External Check
key: check_replication_master.sh
Update interval: 30s
Applications: Oracle
```

4. In Items, create a new Item `Standby archived log sequence`:
```
Name: Standby archived log sequence
Type: External Check
key: check_replication_slave.sh
Update interval: 31s
Applications: Oracle
```

5. In Items, create a new Item `DB2 Oracle Replication Delay (Number of archivelogs behind)`:
```
Name: DB2 Oracle Replication Delay (Number of archivelogs behind)
Type: Calculated
key: archivelog_gap
Formula: last("check_replication_master.sh")-last("check_replication_slave.sh")
Update interval: 1m
Applications: Oracle
```

6. Create a new Trigger `Oracle Replication delay is too high on {HOST.NAME}`:
```
Name: Oracle Replication delay is too high on {HOST.NAME}
Severity: Warning
```
Expression (If the replication gap is higher than 30, then it will trigger): 
```
({TRIGGER.VALUE}=0 and {Template Oracle Standby DB:archivelog_gap.min(10m)}>30) or ({TRIGGER.VALUE}=1 and {Template Oracle Standby DB:archivelog_gap.min(10m)}>29)
```

7. Apply the new template to your Standby Oracle DB.
8. You can monitor the data from the __Latest Data__ page.
