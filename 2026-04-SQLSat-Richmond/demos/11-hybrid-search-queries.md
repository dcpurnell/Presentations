# Script 11: Hybrid Search Queries

## SQL Saturday Richmond: Vector Embeddings with Ollama

## Introduction

Now that we have our vector embeddings and indexes set up, let's talk about how to query them effectively. This is where the "rubber meets the road" in terms of building real applications on top of vector search.

The key concept here is **HYBRID SEARCH** — combining traditional SQL predicates with vector similarity search to get the best of both worlds.

## Why Hybrid Search?

Because in most real-world applications, you don't just want "the most similar vectors" — you want "the most similar vectors that also match these specific criteria."

### Example Use Case

If you're building a course recommendation system, you might want to find:

- Courses that are similar to a user's interests (**vector search**)
- But also filter by department, level, or credit hours (**traditional SQL predicates**)

In this demo, we'll show how to use VECTOR_SEARCH in combination with WHERE clauses to perform hybrid searches. We'll also discuss best practices for over-fetching and post-filtering results to ensure you get relevant and accurate recommendations.

## Important: Over-Fetching and Post-Filtering

VECTOR_SEARCH is designed to return the TOP_N most similar vectors based on the specified metric. However, if you apply additional filters (e.g., `WHERE Department = 'Computer Science'`), you might end up with fewer results than TOP_N after filtering.

### Understanding Query Execution Order

⚠️ **Critical:** VECTOR_SEARCH is evaluated **before** the WHERE clause.

This means:

1. If you set `TOP_N = 50`, VECTOR_SEARCH will return the 50 most similar vectors from the entire dataset
2. Then the WHERE clause will filter those 50 results
3. If none of those 50 results match your WHERE conditions, you could end up with **zero results**

### The Over-Fetching Strategy

To mitigate this, it's a common practice to "over-fetch" by setting TOP_N to a higher value than you actually need.

**Example:**

- If you want the top 10 results after filtering
- Set `TOP_N = 50` or `TOP_N = 100`
- This gives you a larger pool of candidates to filter down from
- Increases the chances of getting enough relevant results

### Trade-offs

**Benefit:** Better user experience by ensuring you have enough relevant results to display

**Cost:** Over-fetching can increase query latency since you're retrieving more vectors than necessary

However, it often leads to better user experience overall.

## HYBRID PATTERNS

All standard SQL, nothing exotic:

1. **VECTOR_DISTANCE + WHERE clause filters** (most common)
2. **VECTOR_DISTANCE + JOINs** (our 1:1 embeddings table pattern — this IS a JOIN)
3. **VECTOR_DISTANCE + Full-Text Search** (keyword AND meaning together)
4. **VECTOR_SEARCH + WHERE** (approximate search with post-filtering)
5. **VECTOR_SEARCH + JOINs** (approximate search with relational filters)
6. **VECTOR_SEARCH + Full-Text Search** (approximate search + keyword filters)
