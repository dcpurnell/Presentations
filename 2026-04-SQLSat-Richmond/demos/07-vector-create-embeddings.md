# Script 07: Creating Vector Embeddings

## SQL Saturday Richmond: Vector Embeddings with Ollama

### Reference

[AI_GENERATE_EMBEDDINGS Function](https://learn.microsoft.com/en-us/sql/t-sql/functions/ai-generate-embeddings-transact-sql?view=sql-server-ver17)

## Options for Creating Embeddings

Which approach you pick matters for architecture:

### 1. ETL Pipeline

Generate embeddings outside SQL Server (Python script, Azure Function, SSIS package). Load vectors into your table.

**Pros:**

- Full control
- Batch processing
- Any model/provider

**Cons:**

- More moving parts
- Another pipeline to maintain

### 2. Batch Job

Scheduled process that embeds new/changed rows. Same as ETL but triggered on a schedule. Good for data that changes periodically (like our course catalog — semester updates).

### 3. In-Database (what we're doing today)

CREATE EXTERNAL MODEL + AI_GENERATE_EMBEDDINGS. SQL Server calls the model directly. No Python, no external scripts. The DBA controls which models are available — change models without touching application code.

### 4. On-Demand (query-time)

Generate embeddings per search request. Every user query hits the model.

⚠️ **LATENCY WARNING:** Each API call adds 50-200ms. For Ollama locally that's tolerable, but for cloud APIs at scale it's a bottleneck. Fine for search queries (one call per search). NOT fine for per-row processing in production.

## Architectural Considerations

For any approach, think about:

- Retry logic
- Error handling
- Cost tracking

Choose based on your team's strengths and operational requirements.

## Cost Planning

*For cloud APIs — Ollama is free*

Cloud embedding APIs run ~$0.02-$0.10 per million tokens.

**Example calculation:**

```text
1M rows × ~100 tokens each = ~$2-$10 to embed entire dataset
```

That's a **one-time cost** if you follow "generate once, query many."

Re-embedding only changed rows (hash comparison) keeps ongoing costs minimal.

## Token Awareness

Embeddings work with **tokens**, not words. Tokens are subword units, roughly 3-4 characters.

**Example:**

```text
"Introduction to Database Design with practical SQL examples"
= 8 words
= ~10 tokens
```

### Model Limits

Our Ollama model (nomic-embed-text) has a **2,048 token limit** (~1,300-1,500 words).

**Rule of thumb:** Estimate 1.3-1.5× the word count.

Our course descriptions (~50-150 words) are safe, but if you're embedding full documents (white papers, research articles, documentation), you **MUST** implement a chunking strategy.

### Chunking Strategy for Long Documents

Split long text into overlapping segments:

- 500-word chunks with 50-word overlap
- Embed each separately
- Store chunk metadata:
  - `document_id`
  - `chunk_number`
  - `position`

This allows you to reconstruct context during retrieval.
