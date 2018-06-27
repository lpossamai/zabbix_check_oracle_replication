#
# zabbix_check_oracle_replication
#

I came across a Standard Oracle DB with no DataGuard. Everything done on the Database (Monitoring) was done via scripting, as on the Standard version the Standby server cannot have the listener running.
Because of that, I had to develop a simple Bash script so I could monitor the replication delay between a Master and a Slave Oracle DB.

NOTE: This was done on Oracle 11G Standard Edition

What we'll be using:
1. Zabbix Server (Make sure you have the Zabbix Agent running)
2. Bash
3. You'll need the System/sys Oracle password
4. You'll need SSH access to the Oracle DB you want to monitor

This is how the graph looks like after applying these scripts:
![Replication Delay between a Master and a Slave Oracle DB](https://github.com/lpossamai/zabbix_check_oracle_replication/blob/master/docs/images/db2_archive_log_photo.png)
