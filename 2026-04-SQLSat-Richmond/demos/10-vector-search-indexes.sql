-- Script 10: Vector Search Indexes
-- SQL Saturday Richmond: Vector Embeddings with Ollama

-- Create the DiskANN vector index
-- NOTE: This makes the embeddings table READ-ONLY on-prem!
-- That's why we use the separate 1:1 table pattern.

USE CourseCatalog;
GO

-- Enable vector indexes (still in preview as of CU3)
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO

-- float 32 (4 bytes × 768 dimensions = 3,072 bytes per embedding)
CREATE VECTOR INDEX IX_Vector_Embedding_Cosine
ON dbo.CourseEmbeddings_768_f32(Embedding)
WITH (TYPE = 'DiskANN', METRIC = 'cosine');
GO

-- float 16 (2 bytes × 768 dimensions = 1,536 bytes per embedding)
CREATE VECTOR INDEX IX_Vector_Embedding_Cosine
ON dbo.CourseEmbeddings_768_f16(Embedding)
WITH (TYPE = 'DiskANN', METRIC = 'cosine');
GO

-- VECTOR_SEARCH - Optimized vector search using DiskANN index
-- This is the PREFERRED method for production vector search queries.
-- Requires a VECTOR INDEX to use the optimized DiskANN algorithm.
-- Much faster than VECTOR_DISTANCE on large datasets!

-- https://github.com/dcpurnell/Presentations/blob/main/2026-04-SQLSat-Richmond/images/diskann-infographic.png

-- Example: Search for courses related to AI and machine learning
-- using the VECTOR_SEARCH function with the DiskANN index.
DECLARE @searchText NVARCHAR(500) = N'artificial intelligence machine learning neural networks deep learning predictive models';
DECLARE @embedding768 VECTOR(768) = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL ollama768);

-- Join pattern: VECTOR_SEARCH -> CourseEmbeddings -> CourseCatalog
-- VECTOR_SEARCH returns the primary key (EmbeddingID) + distance

SELECT 
    c.CourseID,
    c.CourseTitle,
    c.Department,
    c.College,
    c.CourseLevel,
    c.Credits,
    CAST(vs.distance AS DECIMAL(8,6)) AS similarity,
    c.CourseDescription
FROM
    VECTOR_SEARCH(
        TABLE = dbo.CourseEmbeddings_768_f32 ce,
        COLUMN = Embedding,
        SIMILAR_TO = @embedding768,
        METRIC = 'cosine',
        TOP_N = 20
    ) AS vs
INNER JOIN dbo.CourseCatalog c ON ce.CourseID = c.CourseID
ORDER BY vs.distance;
GO

-- Comparing EXACT vs APPROXIMATE search performance
-- Shows the difference between VECTOR_DISTANCE (exact) and VECTOR_SEARCH (approximate)
-- With DiskANN indexes, VECTOR_SEARCH is much faster on large datasets
-- while maintaining high recall (typically 90%+ accuracy)

-- Example: Search for data science and statistics courses
DECLARE @searchText NVARCHAR(500) = N'data science statistics analytics data mining statistical analysis';
DECLARE @embedding768 VECTOR(768) = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL ollama768);

-- EXACT search using VECTOR_DISTANCE
-- Scans every row, computes exact distance - SLOW but 100% accurate
-- Use for up to 50K rows
-- https://learn.microsoft.com/en-us/sql/sql-server/ai/vectors?view=sql-server-ver17#exact-search-and-vector-distance-exact-nearest-neighbors

SELECT TOP 20
    'VectorDistance' AS search_type,
    c.CourseID,
    c.CourseTitle,
    c.Department,
    CAST(VECTOR_DISTANCE('cosine', ce.Embedding, @embedding768) AS DECIMAL(8,6)) AS distance
FROM dbo.CourseEmbeddings_768_f32 ce
INNER JOIN dbo.CourseCatalog c ON ce.CourseID = c.CourseID
WHERE ce.Embedding IS NOT NULL
ORDER BY VECTOR_DISTANCE('cosine', ce.Embedding, @embedding768);
GO

-- APPROXIMATE search using VECTOR_SEARCH
-- Uses DiskANN index for fast approximate nearest neighbor - FAST with high recall
DECLARE @searchText NVARCHAR(500) = N'data science statistics analytics data mining statistical analysis';
DECLARE @embedding768 VECTOR(768) = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL ollama768);

SELECT
    'VectorSearch' AS search_type,
    c.CourseID,
    c.CourseTitle,
    c.Department,
    CAST(vs.distance AS DECIMAL(8,6)) AS distance
FROM VECTOR_SEARCH(
    TABLE = dbo.CourseEmbeddings_768_f32 AS ce,
    COLUMN = Embedding,
    SIMILAR_TO = @embedding768,
    METRIC = 'cosine',
    TOP_N = 20
) AS vs
INNER JOIN dbo.CourseCatalog c ON ce.CourseID = c.CourseID
ORDER BY vs.distance;
GO

-- Let's UNION ALL the results to compare side by side
-- We want to order by distance to show the differences in ranking 
--between exact and approximate search
DECLARE @searchText NVARCHAR(500) = N'data science statistics analytics data mining statistical analysis';
DECLARE @embedding768 VECTOR(768) = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL ollama768);   

With CTE_Distance AS (
    SELECT TOP 20
        'VectorDistance' AS search_type,
        c.CourseID,
        c.CourseTitle,
        c.Department,
        c.TermID,
        CAST(VECTOR_DISTANCE('cosine', ce.Embedding, @embedding768) AS DECIMAL(8,6)) AS distance
    FROM dbo.CourseEmbeddings_768_f32 ce
    INNER JOIN dbo.CourseCatalog c ON ce.CourseID = c.CourseID
    WHERE ce.Embedding IS NOT NULL
    ORDER BY VECTOR_DISTANCE('cosine', ce.Embedding, @embedding768)
),
CTE_Search AS (
    SELECT TOP 20
        'VectorSearch' AS search_type,
        c.CourseID,
        c.CourseTitle,
        c.Department,
        c.TermID,
        CAST(vs.distance AS DECIMAL(8,6)) AS distance
    FROM VECTOR_SEARCH(
        TABLE = dbo.CourseEmbeddings_768_f32 AS ce,
        COLUMN = Embedding,
        SIMILAR_TO = @embedding768,
        METRIC = 'cosine',
        TOP_N = 20
    ) AS vs
    INNER JOIN dbo.CourseCatalog c ON ce.CourseID = c.CourseID
    ORDER BY vs.distance
)
SELECT * FROM CTE_Distance
UNION ALL
SELECT * FROM CTE_Search
ORDER BY distance, CourseID, search_type;
GO
