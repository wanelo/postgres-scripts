#!/bin/bash
 
function usage {
  echo "Usage: $0 <master_ip> [data_dir]"
  echo "   master_ip : IP or fqdn to reach PostgreSQL master"
  echo "   data_dir  : Data directory into which to install PostgreSQL : default /var/pgsql/data93"
  echo
  echo "   Note: pg_basebackup must be in PATH"
}
 
if [ -z $1 ]; then
  usage
  exit 1
fi

DEFAULT_DATA_DIR='/var/pgsql/data93'

MASTER_IP=$1
DATA_DIR=${2:-$DEFAULT_DATA_DIR}
SERVICE_NAME=$(svcs -a | grep postgres | awk '{ print $3 }')

# Ensure services don't interrupt us
if [ ! -z $SERVICE_NAME ]; then
  svcadm disable -s $SERVICE_NAME
fi
svcadm disable -s chef-client

# Clean up previous attempts
rm -rf $DATA_DIR.original
mv $DATA_DIR $DATA_DIR.original

# Tune TCP settings
ndd -set /dev/tcp tcp_max_buf 2097152
ndd -set /dev/tcp tcp_cwnd_max 2097152
ndd -set /dev/tcp tcp_recv_hiwat 2097152
ndd -set /dev/tcp tcp_xmit_hiwat 2097152

# Run base backup
pg_basebackup -x -D $DATA_DIR -P -U postgres -h $MASTER_IP
chown -R postgres:postgres $DATA_DIR

# Configure recovery.conf file
cat > $DATA_DIR/recovery.conf <<DELIM
standby_mode = 'on'
primary_conninfo = 'host=$MASTER_IP'
# stops replication, becomes master if the file is found
trigger_file = '$DATA_DIR/trigger'

restore_command = 'cp /var/pgsql/data92/wal_archive/%f %p'
recovery_target_timeline = 'latest'
DELIM

chown postgres:postgres $DATA_DIR/recovery.conf

# Update Postgres settings (local IP) and start it
chef-client
