[mysqld]
read_only=ON
super_read_only=ON


[mysqld]
gtid_mode=ON
enforce-gtid-consistency=ON
net stop MySQL80
net start MySQL80

CHANGE MASTER TO 
MASTER_HOST='192.168.1.73',
MASTER_USER='replicator',
MASTER_PASSWORD='root',
MASTER_LOG_FILE='TESS-bin.000045',
MASTER_LOG_POS=197,
MASTER_AUTO_POSITION=1;


