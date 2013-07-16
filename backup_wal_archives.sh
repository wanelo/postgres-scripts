#!/bin/bash

rm -rf /backups/$(hostname)/pgsql/wal_archive
mkdir -p /backups/$(hostname)/pgsql/wal_archive
cp -v -r /var/pgsql/data92/wal_archive/* /backups/$(hostname)/pgsql/wal_archive/
