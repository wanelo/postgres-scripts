#!/bin/bash
 
function usage {
  echo "Usage: $0 <master_ip>"
}
 
if [ -z $1 ]; then
  usage
  exit 1
fi

MASTER_IP=$1

svcadm disable -s postgres924
svcadm disable -s chef-client

mv -f /var/pgsql/data92 /var/pgsql/data92.original
/opt/local/postgres-9.2.4/bin/pg_basebackup -x -D /var/pgsql/data92 -P -U postgres -h $MASTER_IP
chown -R postgres:postgres /var/pgsql/data92

cat > /var/pgsql/data92/recovery.conf <<DELIM
standby_mode = 'on'
primary_conninfo = 'host=$MASTER_IP'
# stops replication, becomes master if the file is found
trigger_file = '/var/pgsql/data92/trigger'

restore_command = 'cp /var/pgsql/data92/wal_archive/%f %p'
recovery_target_timeline = 'latest'
DELIM

chown postgres:postgres /var/pgsql/data92/recovery.conf

chef-client ## updates IP address in postgresql.conf
