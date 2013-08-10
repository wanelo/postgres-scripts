#!/bin/bash

rm -rf /backups/$HOSTNAME/pgsql/wal_archive
mkdir -p /backups/$HOSTNAME/pgsql/wal_archive
cp -v -r /var/pgsql/data92/wal_archive/* /backups/$HOSTNAME/pgsql/wal_archive/
