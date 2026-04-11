# Script 13: DBA Evolving Role

## SQL Saturday Richmond: Vector Embeddings with Ollama

## Let's Zoom Out

Five years ago, the DBA managed backups, indexes, and availability groups. That was the job. Important work, but well-defined.

### Today — the DBA is being asked to support

- Vector data types and embedding columns
- REST API calls FROM WITHIN the database engine
- External model registration and management
- Local AI model infrastructure (Ollama, Docker, nginx)
- Embedding pipelines and refresh strategies
- Storage planning for entirely new data shapes

## The Blurring Lines

**Kendra Little said it well:** *"We are all developers now."*

The DBA-developer line is blurring. Version control, REST APIs, containers, AI infrastructure — that's DBA work in 2026.

## Data Privacy and Governance

For those of you worried about data privacy — that's a governance decision the DBA enables.

**FERPA, HIPAA, PII** — keeping data on-prem with Ollama is a DBA architecture choice. You're not just maintaining databases anymore. You're making strategic decisions about where data flows and how AI interacts with it.

## The Pace of Change

This space is moving **FAST**. Between when I prepped this talk and today, Microsoft announced DML support for vector indexes in Azure SQL.

Stay on top of:

- Release notes
- Conferences
- Community resources

## Your Roadmap

### Phase 1: LEARN (you're doing this right now)

Vectors, embeddings, similarity, indexes. Understand the concepts before touching the tools. That's what today's session is about.

### Phase 2: EXPERIMENT

Pull the docker-compose stack. Install SQL Server 2025 + Ollama. Generate embeddings, run queries, break things.

⚠️ **Non-production environment ONLY.**

My GitHub repo has everything you need.

### Phase 3: PILOT

Pick a low-risk use case. Internal search tool, small dataset, something where "pretty good" results are fine.

Build end-to-end:

- Embedding pipeline
- Vector index
- Search queries
- Monitoring

Measure recall, performance, and user satisfaction.

### Phase 4: PRODUCTION

Critical applications, real monitoring, maintenance procedures. All the DBA considerations from [script #12](12-dba-considerations.md) apply here:

- Capacity planning
- Security
- GPUs
- Backup impact
- Refresh strategies

### Phase 5: OPTIMIZE AND EXPAND

- Tune performance
- Try larger models
- Add more use cases
- Share knowledge with your team

**You're the vector search expert now.**

## Key Takeaway

Vector search is just another query pattern. All data in one place — no separate vector databases.

Apply your existing DBA skills:

- Monitoring
- Security
- Capacity planning
- Backup and restore

It's all the same principles you already know.

## Final Thoughts

**Stay curious, stay current.**

---

### Resources

**GitHub repo:** <https://github.com/dcpurnell/Presentations/tree/main/2026-04-SQLSat-Richmond>
