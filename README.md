postgres-scripts
================

Only tested on SmartOS.

## Dependencies

* (postmodern)[https://github.com/wanelo/postmodern] installed

## Start replication

Creating a new replica from a master:

```bash
export PATH=/opt/local/postgres-9.3.0/bin:$PATH
\curl -L https://raw.github.com/wanelo/postgres-scripts/master/replicate.sh | bash -s <master_ip> /var/pgsql/data93
```

Ensure that the pgbasebackup binary for your version of Postgres is in PATH before running this script.
