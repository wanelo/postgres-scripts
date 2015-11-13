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
SERVICE_NAME=$(svcs | grep postgres | awk '{ print $3 }')

echo "Using -- data directory: $DATA_DIR"
echo "           service name: $SERVICE_NAME"
echo "           ip of master: $MASTER_IP"
echo

# Ensure services don't interrupt us
if [ ! -z "${SERVICE_NAME}" ]; then
  echo "Disabling service ${SERVICE_NAME}..."
  svcadm disable -s ${SERVICE_NAME}
fi
echo "Disabling chef-client..."
svcadm disable -s chef-client

# Clean up previous attempts
rm -rf $DATA_DIR.orig
test -d $DATA_DIR
if [ $? -eq 0 ]; then
  echo "Moving $DATA_DIR to $DATA_DIR.orig..."
  mv $DATA_DIR $DATA_DIR.orig
fi

# Tune TCP settings
ndd -set /dev/tcp tcp_max_buf 2097152
ndd -set /dev/tcp tcp_cwnd_max 2097152
ndd -set /dev/tcp tcp_recv_hiwat 2097152
ndd -set /dev/tcp tcp_xmit_hiwat 2097152

# Run base backup
echo "Starting basebackup, using -X fetch"
pg_basebackup -X fetch --checkpoint=fast -D $DATA_DIR -P -U postgres -h $MASTER_IP

if [ $? -ne 0 ]; then
  echo "ERROR: basebackup failed" >&2
  exit 1
fi

echo "Chowning $DATA_DIR"
chown -R postgres:postgres $DATA_DIR

# Configure recovery.conf file
echo "Configuring replica: $DATA_DIR/recovery.conf"
cat > $DATA_DIR/recovery.conf <<DELIM
standby_mode = 'on'
primary_conninfo = 'host=$MASTER_IP'
# stops replication, becomes master if the file is found
trigger_file = '$DATA_DIR/trigger'

restore_command = 'postmodern restore --filename %f --path %p'
recovery_target_timeline = 'latest'
DELIM

chown postgres:postgres $DATA_DIR/recovery.conf

# Update Postgres settings (local IP) and start it
echo "Running chef to update configuration"
chef-client > /dev/null

if [ $? -ne 0 ]; then
  echo "ERROR: chef-client failed" >&2
  exit 1
fi

echo "Done"
