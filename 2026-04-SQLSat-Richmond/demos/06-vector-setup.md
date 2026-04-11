# Script 06: Vector Embeddings Setup

## SQL Saturday Richmond: Vector Embeddings with Ollama

### References

- [CREATE EXTERNAL MODEL](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-external-model-transact-sql?view=sql-server-ver17)
- [AI_GENERATE_EMBEDDINGS](https://learn.microsoft.com/en-us/sql/t-sql/functions/ai-generate-embeddings-transact-sql?view=sql-server-ver17)

## CREATE EXTERNAL MODEL

CREATE EXTERNAL MODEL is like creating a linked server, but for AI.
You're telling SQL Server: "here's where to send text to get vectors."
The JSON payload specifies the provider (ollama), the model name,
and the endpoint URL.

### Ollama nomic-embed-text Model

<https://ollama.com/library/nomic-embed-text>

- 768 dimensions
- float32 or float16 precision options
- Designed for text embedding tasks
- 275MB model size (loads and generates embeddings quickly)

### Supported Providers

- Azure OpenAI
- OpenAI
- Ollama
- ONNX Runtime

We're using Ollama, but the same CREATE EXTERNAL MODEL pattern works
for all of them. Swap providers without changing your queries.

### AI_GENERATE_EMBEDDINGS Function

AI_GENERATE_EMBEDDINGS is the magic function. Pass it text and a
model name — it calls Ollama, gets back a vector, returns it as
the VECTOR data type. All in T-SQL. No Python needed.

### ⚠️ MODEL LOCK-IN — This is Critical

Pick one model and stick with it for your entire dataset. You
**CANNOT** mix embeddings from different models. Each model creates
its own embedding space — a unique mathematical coordinate system.

Text embedding 3-small (OpenAI) vectors are NOT comparable to
nomic-embed-text (Ollama) vectors, even if they're the same dimensions.

**It's like comparing latitude/longitude on Earth to x-y coordinates on Mars.**

The numbers exist, but the distance calculations are meaningless.
If you change models later, you must re-embed your ENTIRE dataset.

## What Are Vectors?

A vector is just a list of numbers that represents MEANING.
An embedding model reads text and outputs these numbers,
placing similar concepts close together in mathematical space.

```text
"database"   → [0.12, -0.45, 0.78, ...]   ← these two are
"SQL Server" → [0.11, -0.43, 0.80, ...]   ← close together
"banana"     → [-0.91, 0.33, -0.02, ...]  ← this one is far away
```

## Vector Data Types in SQL Server 2025

### VECTOR(n)

- 32-bit float (float32)
- Up to 1,998 dimensions
- Full precision, broader model compatibility

### VECTOR(n, float16)

- 16-bit half-precision (FP16)
- Up to 3,996 dimensions
- Half the storage, slight precision loss
- Best for large-scale approximate similarity
- Requires preview features enabled

### Choosing Dimensions

The "n" is the number of dimensions your embedding model outputs.
Use factors of 2 (e.g., 768, 1024, 1568) for best performance.

**Example:** Ollama's nomic-embed-text produces 768 dimensions
→ SQL datatype: `VECTOR(768)`

## Visual Example: 3-Dimensional Embedding

Let's see what "database" might look like in 3D space
(Real embeddings have 768 dimensions, but 3D helps us visualize)

### FLOAT32 (VECTOR(3)) - Full Precision

```text
"database" → [0.12456789, -0.45678912, 0.78901234]
             │           │            │
             │           │            └─ 8 decimal places
             │           └─ negative values preserved
             └─ precise fractional values

Storage:   12 bytes (4 bytes × 3 dimensions)
Precision: ~7 decimal digits
```

### FLOAT16 (VECTOR(3, float16)) - Half Precision

```text
"database" → [0.1245, -0.4570, 0.7891]
             │        │        │
             │        │        └─ 4 decimal places
             │        └─ some rounding occurs
             └─ slightly less precise

Storage:   6 bytes (2 bytes × 3 dimensions) - HALF the space!
Precision: ~3-4 decimal digits
```

### The Difference

```text
Float32: [0.12456789, -0.45678912, 0.78901234]
Float16: [0.1245,     -0.4570,     0.7891    ]
         └────────────────┬──────────────────┘
                     Rounded, but still VERY close!
```

For similarity search, float16 is usually "close enough"
and saves 50% storage - critical when scaling to millions of vectors!

### Visual Reference

[Vector 2D Chart](https://github.com/dcpurnell/Presentations/blob/main/2026-04-SQLSat-Richmond/images/vector-2d-chart.png)
