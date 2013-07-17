#!/bin/bash

export MASTER=$1
export SERVICE=postgres924

if [ -z $MASTER ]; then
  echo "USAGE: $0 <fqdn of master>"
  exit 1
fi

svcadm disable -s $SERVICE
mkdir -p /var/pgsql/data92/wal_archive
cp -v -r  /backups/$MASTER/pgsql/wal_archive/* /var/pgsql/data92/wal_archive/
chown -R postgres:postgres /var/pgsql/data92/wal_archive
svcadm enable -s $SERVICE
