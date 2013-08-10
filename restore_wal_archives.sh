#!/bin/bash

export MASTER=$1
export SERVICE=postgres924

function usage {
  echo "USAGE: $0 <master_fqdn>"
}

if [ -z $MASTER ]; then
  usage
  exit 1
fi

if [ ! -f /var/pgsql/data92/recovery.conf ]; then
  echo "Script can only be run on a Postgres replica. Missing recovery.conf."
  echo
  usage
  exit 3
fi

svcadm disable -s $SERVICE
rm -rf /var/pgsql/data92/wal_archive
mkdir -p /var/pgsql/data92/wal_archive
cp -v -r  /backups/$MASTER/pgsql/wal_archive/* /var/pgsql/data92/wal_archive/
chown -R postgres:postgres /var/pgsql/data92/wal_archive
svcadm enable -s $SERVICE
