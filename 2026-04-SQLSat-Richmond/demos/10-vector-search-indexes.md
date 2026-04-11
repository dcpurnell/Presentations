# Script 10: Vector Search Indexes

## SQL Saturday Richmond: Vector Embeddings with Ollama

Create the DiskANN vector index

⚠️ **NOTE:** This makes the embeddings table READ-ONLY on-prem! That's why we use the separate 1:1 table pattern.

## How DiskANN Graph Search Works

When you search:

1. **Start at an ENTRY POINT** (a well-connected node near the center)
   - Single vector that has the smallest average distance to all other vectors in the graph
2. **Look at all neighbors** of the current node and create candidate list
3. **HOP to whichever neighbor** is closest to your search vector
4. **Repeat** until no neighbor is closer than where you are
5. **Return the top K** closest vectors found during navigation

## References

- [SQL Server Vector Documentation](https://learn.microsoft.com/en-us/sql/sql-server/ai/vectors?view=sql-server-ver17)
- [CREATE VECTOR INDEX](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-vector-index-transact-sql?view=sql-server-ver17#upgrade-vector-indexes-to-the-latest-version)
- [VECTOR_SEARCH Function](https://learn.microsoft.com/en-us/sql/t-sql/functions/vector-search-transact-sql?view=sql-server-ver17)
- [DiskANN Research Paper](https://www.microsoft.com/en-us/research/publication/diskann-fast-accurate-billion-point-nearest-neighbor-search-on-a-single-node/)

## VECTOR_SEARCH - Optimized Search

This is the **PREFERRED method** for production vector search queries.

- Requires a VECTOR INDEX to use the optimized DiskANN algorithm
- Much faster than VECTOR_DISTANCE on large datasets!

### Visual Reference

[DiskANN Infographic](https://github.com/dcpurnell/Presentations/blob/main/2026-04-SQLSat-Richmond/images/diskann-infographic.png)

## Detailed Search Flow for TOP 20

1. **Start at the entry point** — it has, say, 15 edges. Evaluate all 15 neighbors. Add all of them to the candidate list ranked by distance.

2. **Pop the closest candidate** off the list. Visit that node. Evaluate all of its neighbors (maybe 12 edges). Add the new ones to the candidate list.

3. **Repeat** — always visiting the most promising unvisited candidate next.

4. **Keep a running "results" list** of the 20 best vectors seen so far across ALL nodes visited.

5. **Stop** when no unvisited candidate is closer than the worst result in your top 20.

## RECALL@K — How Accurate is Approximate?

Recall@10 = "Of the true top 10 nearest neighbors, how many did the approximate search actually find?"

**DiskANN typical: 95-99% recall@10**

### Example

True top 10 courses for "data analytics":

```text
[A, B, C, D, E, F, G, H, I, J]
```

DiskANN returns:

```text
[A, B, C, D, E, F, G, H, I, K]
```

**Result:** 9/10 = 90% recall

K was close enough to be in the neighborhood but wasn't truly #10. For search results shown to a user, that's perfectly acceptable.
