# Script 09: Vector Distance Queries

## SQL Saturday Richmond: Vector Embeddings with Ollama

Perform vector similarity searches using the generated embeddings. Demonstrates semantic search using VECTOR_DISTANCE with multiple distance metrics. Shows how to find similar courses based on vector embeddings rather than keyword matching.

## VECTOR_DISTANCE Metrics

VECTOR_DISTANCE supports three distance metrics:

1. **COSINE** (default, RECOMMENDED) - measures angle between vectors (0=identical, 2=opposite)
2. **EUCLIDEAN** - measures straight-line distance in vector space
3. **DOT** - measures dot product (higher values = more similar)

All three metrics compare two vectors (arrays of numbers) that represent the "meaning" of text, images, etc. as points in high-dimensional space. Think of each vector as a direction + magnitude (length) in that space.

## Metric Details

### COSINE (default, most common for text/embeddings)

**Measures:** The ANGLE between two vectors (ignores magnitude)

**Range:** 0 to 2  (0 = identical direction, 2 = opposite)

**Analogy:** Two flashlights pointing the same direction are "similar" regardless of how bright (long) each beam is.

**Use when:** Comparing semantic meaning of text, documents, or search queries where the LENGTH of the content shouldn't matter.

### EUCLIDEAN (straight-line distance)

**Measures:** The actual DISTANCE between two points in space

**Range:** 0 to infinity  (0 = same point)

**Analogy:** How far apart two pins are on a corkboard. Sensitive to both direction AND magnitude.

**Use when:** Vectors are normalized to the same scale, or when absolute position matters (e.g., geographic, sensor data, clustering).

### DOT PRODUCT (direction + magnitude combined)

**Measures:** Angle AND magnitude together (projection of one onto another)

**Range:** -infinity to +infinity  (higher = more similar)

⚠️ **NOTE:** ONLY metric where HIGHER is better (others: lower = closer)

**Analogy:** How much two rowers are pulling in the same direction AND how hard each is pulling.

**Use when:** Your embedding model was trained for dot product similarity (e.g., some OpenAI models) or magnitude carries meaning like popularity or confidence.

## Quick Decision Guide

- **Text search / RAG / semantic similarity** → COSINE
- **Normalized numeric data / clustering** → EUCLIDEAN
- **Model docs say "use dot product"** → DOT

### Why Cosine for Text Embeddings?

Cosine measures the **ANGLE** between two vectors, not the distance.

- **Distance** = length of the document
- **Direction** = meaning
- **Magnitude** = irrelevant for text

A short course description and a long one can have very different magnitude (longer text → larger vector magnitude), but if they describe the same topic, the angle between them is small. **Cosine ignores magnitude. That's exactly what we want.**

## COSINE DISTANCE SCALE

- **0** = identical (vectors point the same direction)
- **1** = orthogonal (no relationship)
- **2** = opposite (vectors point opposite directions)

Lower is better (0 to 2 scale).

### Practical Interpretation

Here's what the numbers actually mean when you're reviewing results:

| Distance | Interpretation |
|----------|----------------|
| 0.0 – 0.2 | Nearly identical meaning (same topic, same intent) |
| 0.2 – 0.4 | Very similar (strong semantic match) |
| 0.4 – 0.6 | Moderate similarity (related but different focus) |
| 0.6 – 0.8 | Weak similarity (loosely connected concepts) |
| 0.8+ | Different topics, minimal relationship |

## What Actually Happens During Vector Search

1. User types natural language: "courses about data ethics"
2. SQL Server sends that text to Ollama via `AI_GENERATE_EMBEDDINGS`
3. Ollama returns a 768-dimension vector
4. `VECTOR_DISTANCE` compares that vector against every stored embedding
5. `ORDER BY distance` → most semantically similar results first

**The AI is only in steps 2-3. Everything else is pure SQL Server.**
