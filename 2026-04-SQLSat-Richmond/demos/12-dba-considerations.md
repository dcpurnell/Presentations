# Script 12: DBA Considerations

## SQL Saturday Richmond: Vector Embeddings with Ollama

## Storage Planning

Plan around storage, indexing, and performance for vector data in SQL Server:

| Rows | Dimensions | Precision | Approximate Size |
| ------ | ------------ | ----------- | ------------------ |
| 100K | 1536d | float32 | ~800 MB |
| 1M | 1536d | float32 | ~8 GB |
| 10M | 1536d | float32 | ~80 GB |
| 100M | 1536d | float32 | ~800 GB |

**Formula:** `rows × dimensions × bytes_per_float × ~1.3 (DiskANN overhead)`

### Context

That **8 GB number for 1M rows** puts it in perspective — it's a large clustered index worth of data. This is buffer pool impact. Plan for it the same way you'd plan for any large index.

## Index Storage and Memory

Vector indexes use the buffer pool like any other index in SQL Server.

DiskANN's design leverages **partial caching**:

- Frequently accessed vectors remain in memory
- Less-used vectors stay on disk

This approach complements the buffer pool rather than competing with it.

💡 **Use SSDs for best performance.**

## Versioning

Include the model name in your table or column name, like:

- `CourseEmbeddings_nomic_768_f32`
- `description_vector_ada_002`

⚠️ **When you upgrade models, old embeddings are INCOMPATIBLE** — you must re-embed everything.

Think of the embeddings like a type two dimension:

- You could include a version column
- Or start and end dates if you want to keep old ones around for a while
- But eventually you need to clean them up

## Maintenance Strategy

⚠️ **Tables with vector indexes are READ-ONLY.** No INSERT/UPDATE/DELETE.

### Process for Modifying Data

1. **DROP** vector index
2. **Modify** data (INSERT/UPDATE/DELETE)
3. **Recreate** vector index

This is why the **1:1 embeddings table pattern is essential** — your source data table stays writable at all times.

## Azure SQL Database Update

*Announced at FabCon March 2026*

### New Capabilities

- ✅ **Full DML support** for tables with vector indexes — no longer read-only
- ✅ **Smarter query optimizer** auto-selects between DiskANN and exact KNN
- ✅ **Improved vector quantization** for better storage efficiency

Expected to come to on-prem SQL Server 2025 in a future CU.
