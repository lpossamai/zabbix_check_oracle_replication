conn sys/syspasswordhere@mwdb1 as sysdba
select max(sequence#) a from v$log_history where FIRST_TIME > SYSDATE -1;
exit
