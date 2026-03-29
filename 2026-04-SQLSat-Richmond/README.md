# Using SQL Server's 2025 Vector Embeddings with Ollama

**SQL Saturday Richmond** | April 11, 2026 | 1:10 - 2:10 PM | Room 210

Reynolds Community College, 1651 E Parham Rd, Richmond, VA 23228

**Presenter:** Doug Purnell | Assistant Director of Data Architecture and Reporting, Elon University

## Abstract

SQL Server 2025 introduces native vector data types and AI-assisted capabilities. This allows you to use AI data exploration directly in the database engine. Many organizations are wary of sending sensitive business data to external cloud endpoints for AI processing, but now SQL Server 2025 supports you using a local model. In this session, you'll learn how to securely integrate Ollama with SQL Server 2025 to perform AI-powered vector embeddings and search on-premises, keeping data inside your network. We'll walk through the architecture, configuration, and demos that show how to generate embeddings, define vector columns, and execute similarity search queries all without your data ever leaving your systems.

## Prerequisites

To follow along or reproduce the demos on your own machine, you'll need:

- **Docker Desktop** - [Download](https://www.docker.com/get-started/)
- **SQL Server 2025 (CU1+)** - [Docker image](https://hub.docker.com/r/microsoft/mssql-server) (tag: `2025-latest`)
- **Ollama** - [Download](https://ollama.com/) or `brew install ollama` (macOS)
- **OpenSSL** - `brew install openssl` (macOS) or included with most Linux distros
- **nginx** - `brew install nginx` (macOS) or `apt install nginx` (Linux)
- **VS Code** with the SQL Server (mssql) extension
- **Ollama models:**
  - `ollama pull nomic-embed-text` (768 dimensions, 137M parameters)
  - `ollama pull gte-qwen2-1.5b-instruct` (1536 dimensions, 1.5B parameters)

## Session Agenda

1. **Docker and container setup** - Pull SQL Server 2025 image, spin up container, connect from VS Code
2. **Ollama setup with OpenSSL & nginx** - Install Ollama, generate self-signed cert, configure nginx reverse proxy (Ollama listens HTTP, SQL Server requires HTTPS)
3. **Embedding and vector setup** - CREATE EXTERNAL MODEL, AI_GENERATE_EMBEDDINGS, VECTOR data type, float16 vs float32
4. **VECTOR_DISTANCE and VECTOR_SEARCH** - Distance metrics, DiskANN vector index, execution plan comparison
5. **Practical uses of embeddings** - Hybrid search (vector + WHERE clauses), embedding sync strategies
6. **DBA considerations** - Storage planning, capacity impact, DiskANN limitations, preview feature status
7. **The evolving role of the DBA** - How the DBA role has shifted and what vector search means for your career

## Folder Structure

```
2026-04-SQLSat-Richmond/
+-- README.md            <- You are here
+-- demos/               <- T-SQL and PowerShell demo scripts
+-- setup/               <- Docker, Ollama, nginx, and OpenSSL setup instructions
|   +-- macos-setup.md   <- macOS (Homebrew) setup guide
|   +-- windows-setup.md <- Windows setup (links to Nocentino's repo)
+-- slides/              <- Slide deck (posted after the session)
+-- resources/           <- Reference links and supplementary materials
```

## Quick Start

### 1. Start SQL Server 2025 in Docker

```bash
docker run -d \
  --name sqlserver2025 \
  -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong!Pass123" \
  -p 1433:1433 \
  -m 4g \
  -v sqlserver_data:/var/opt/mssql \
  mcr.microsoft.com/mssql/server:2025-latest
```

### 2. Start Ollama and pull models

```bash
ollama serve &
ollama pull nomic-embed-text
ollama pull gte-qwen2-1.5b-instruct
```

### 3. Set up the HTTPS proxy

See [setup/macos-setup.md](setup/macos-setup.md) for full instructions using OpenSSL + nginx.

**Architecture:**
```
SQL Server 2025 (Docker, port 1433)
    -> HTTPS request to localhost:443
        -> nginx (TLS termination)
            -> HTTP proxy to localhost:11434
                -> Ollama (local embedding model)
```

## Embedding Models Used

| Model | Dimensions | Parameters | License |
|-------|-----------|------------|---------|
| nomic-embed-text | 768 | 137M | Apache 2.0 |
| gte-qwen2-1.5b-instruct | 1536 | 1.5B | Apache 2.0 |

## Vector Column Storage

| Model | Dimensions | float32 (bytes/row) | float16 (bytes/row) |
|-------|-----------|---------------------|---------------------|
| nomic-embed-text | 768 | 3,072 | 1,536 |
| gte-qwen2-1.5b-instruct | 1536 | 6,144 | 3,072 |

Note: 768d x float32 = 1536d x float16 = 3,072 bytes (same storage, different tradeoff)

## Resources

### Microsoft Documentation

- [Vector Data Type](https://learn.microsoft.com/en-us/sql/t-sql/data-types/vector-data-type?view=sql-server-ver17)
- [VECTOR_SEARCH (T-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/vector-search-transact-sql?view=sql-server-ver17)
- [VECTOR_DISTANCE (T-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/vector-distance-transact-sql?view=sql-server-ver17)
- [CREATE VECTOR INDEX (DiskANN)](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-vector-index-transact-sql?view=sql-server-ver17)
- [AI_GENERATE_EMBEDDINGS (T-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/ai-generate-embeddings-transact-sql?view=sql-server-ver17)
- [CREATE EXTERNAL MODEL (T-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-external-model-transact-sql?view=sql-server-ver17)
- [Vector Data Type - Half Precision Float](https://learn.microsoft.com/en-us/sql/t-sql/data-types/vector-data-type-half-precision-float?view=sql-server-ver17)

### Courses

- [SQLSkills AIVSE - Vector Search Essentials (Joe Sack)](https://www.sqlskills.com/sql-server-training/aivse/)
- [SQLSkills AIVSP - Vector Search in Practice (Joe Sack)](https://www.sqlskills.com/sql-server-training/aivsp/)
- [Get AI-Ready With Erik (Erik Darling)](https://erikdarling.com/new-course-get-ai-ready-with-erik/)

### Video / Podcast

- [SQL Server 2025 YouTube Playlist (Ben Weissman & Anthony Nocentino)](https://www.youtube.com/playlist?list=PLnbFVhkPvSdXqhh0F_x6UjHLgcOnKwJge)
- [SQL Down Under Show 94 - Ben Weissman](https://blog.greglow.com/2026/02/11/sql-down-under-show-94-with-guest-ben-weissman-discussing-vectors-rest-and-ai-in-sql-server-2025/)

### Tutorials

- [Getting Started with Vector Search Using Ollama - Nocentino](https://www.nocentino.com/posts/2025-05-19-ollama-sql-faststart) | [GitHub](https://github.com/nocentino/ollama-sql-faststart)
- [Scaling SQL Server 2025 Vector Search with Load-Balanced Ollama](https://www.nocentino.com/posts/2025-09-27-scaling-ollama-load-balancing)
- [Ollama Quick Start - SQLBek](https://sqlbek.wordpress.com/2025/05/19/ollama-quick-start/)
- [Embeddings with EXTERNAL MODEL + Ollama + GPU](https://www.architecture-performance.fr/ap_blog/get-your-embeddings-on-sql-server-2025-with-ai_generate_embeddings-and-external-model-using-ollama-local-and-your-gpu/)

### Docker + SQL Server 2025

- [SQL Server 2025 CU1 Fixes AVX Issue (Nocentino)](https://www.nocentino.com/posts/2026-02-02-sql-server-2025-cu1-fixes-avx-issue/)
- [RTM AVX Workaround (Nocentino)](https://www.nocentino.com/posts/2025-11-26-sql-server-2025-docker-desktop-avx-issue/)
- [Ben Weissman & Nocentino Companion Repo](https://github.com/bweissman/code/tree/master/SQL%202025/Anthony%20and%20Ben)

### Conference Recaps (FabCon & SQLCon 2026)

- [FabCon/SQLCon 2026 Announcements - James Serra](https://www.jamesserra.com/archive/2026/03/announcements-from-the-microsoft-fabric-community-conference-4/)
- [FabCon and SQLCon 2026 - Azure Blog](https://azure.microsoft.com/en-us/blog/fabcon-and-sqlcon-2026-unifying-databases-and-fabric-on-a-single-data-platform/)
- [DiskANN Vector Index Improvements](https://devblogs.microsoft.com/azure-sql/diskann-vector-index-improvements/)

### The Evolving DBA Role

- [How the DBA Role is Changing (2018) - Curated SQL](https://curatedsql.com/2018/01/02/how-the-dba-role-is-changing/)
- [How the Role of the DBA is Changing in 2022 - DBTA](https://www.dbta.com/Editorial/News-Flashes/How-the-Role-of-the-DBA-is-Changing-in-2022-151756.aspx)
- [The Evolution of the DBA - DBTA](https://www.dbta.com/Editorial/Think-About-It/The-Evolution-of-the-DBA-More-Than-Just-a-Keeper-of-Databases-170939.aspx)
- [Bad News DBAs: We Are All Developers Now - Kendra Little](https://kendralittle.com/2026/02/09/bad-news-dbas-we-are-all-developers-now/)
- [The Ever-Changing Role of the DBA in 2026 - DBTA](https://www.dbta.com/Editorial/News-Flashes/The-Ever-Changing-Role-of-the-Database-Administrator-in-2026-173903.aspx)
- [Impact of Data Governance on Database Administration - DBTA](https://www.dbta.com/Columns/DBA-Corner/The-Impact-of-Data-Governance-on-Database-Administration-169384.aspx)

### Other

- [SQL Server 2025 Embraces Vectors (RTM Blog)](https://devblogs.microsoft.com/azure-sql/sql-server-2025-embraces-vectors-setting-the-foundation-for-empowering-your-data-with-ai/)
- [Pure Storage - AI-Powered Search in SQL Server 2025](https://blog.purestorage.com/purely-technical/sql-server-2025-enterprise-ai-without-the-learning-curve/)
- [MSSQLTips - SQL Server 2025 Vector Search](https://www.mssqltips.com/sqlservertip/8299/vector-search-in-sql-server/)
