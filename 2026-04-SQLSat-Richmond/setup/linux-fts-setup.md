# Installing Full-Text Search in SQL Server 2025 Linux Containers

SQL Server 2025 does not ship an `-fts` tagged Docker image (unlike SQL Server 2022).
To enable Full-Text Search, you install the `mssql-server-fts` package directly inside
the running container.

## Why?

The base `mcr.microsoft.com/mssql/server:2025-latest` container ships as a minimal
Ubuntu 24.04 image — no `curl`, no `gpg`, and no SQL Server package repository
configured. The `mssql-server-fts` package lives in Microsoft's SQL Server 2025 apt
repository, so we need to add it before the install will work.

## Prerequisites

- Docker Desktop installed and running
- SQL Server 2025 container already created and running

## Step 1: Install FTS into the running container

This single command handles everything — installs `curl` and `gpg` (missing from the
minimal image), adds the Microsoft SQL Server 2025 apt repository, and installs the
Full-Text Search package:

```bash
docker exec -it -u root ollama-sql-faststart-sql1-1 bash -c "
  apt-get update &&
  apt-get install -y curl gnupg &&
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes -o /usr/share/keyrings/microsoft-prod.gpg &&
  curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/mssql-server-2025.list | tee /etc/apt/sources.list.d/mssql-server-2025.list &&
  apt-get update &&
  apt-get install -y mssql-server-fts
"
```

### What each line does

| Line | Purpose |
|------|---------|
| `apt-get update` | Refresh package index for the default Ubuntu repos |
| `apt-get install -y curl gnupg` | Install tools needed to add the Microsoft repo |
| `curl ... \| gpg --dearmor ...` | Download and trust Microsoft's GPG signing key |
| `curl ... \| tee ...` | Add the SQL Server 2025 apt repository |
| `apt-get update` (second time) | Refresh package index now that the new repo is added |
| `apt-get install -y mssql-server-fts` | Install Full-Text Search |

## Step 2: Restart the container

Full-Text Search requires a SQL Server restart to activate:

```bash
docker restart ollama-sql-faststart-sql1-1
```

## Step 3: Verify the installation

Connect to the instance and run:

```sql
SELECT SERVERPROPERTY('IsFullTextInstalled') AS FullTextInstalled;
-- Expected: 1
```

## Reference

- [Install SQL Server Full-Text Search on Linux](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup-full-text-search?view=sql-server-ver17)
- [SQL Server 2025 Docker Hub](https://hub.docker.com/r/microsoft/mssql-server)