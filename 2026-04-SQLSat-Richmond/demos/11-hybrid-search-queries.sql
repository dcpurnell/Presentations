-- Script 11: Hybrid Search Queries
-- SQL Saturday Richmond: Vector Embeddings with Ollama

USE CourseCatalog;
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
    c.TermID,
    c.CourseDescription,
    CAST(vs.distance AS DECIMAL(8,6)) AS distance
FROM VECTOR_SEARCH(
    TABLE = dbo.CourseEmbeddings_768_f32 AS ce,
    COLUMN = Embedding,
    SIMILAR_TO = @embedding768,
    METRIC = 'cosine',
    TOP_N = 50
) AS vs
INNER JOIN dbo.CourseCatalog c ON ce.CourseID = c.CourseID
WHERE c.Department = 'Mathematics' -- Traditional SQL filter
AND c.TermID = 'Spring27' -- Another filter example
AND CONTAINS(CourseDescription, '"data science"') -- Full-text search filter
ORDER BY vs.distance;
GO

/*
Course Description example for testing hybrid search filters:
A rigorous treatment of probability theory and statistical inference. 
Topics include random variables, probability distributions, expectation, 
moment generating functions, maximum likelihood estimation, and hypothesis 
testing. Provides the mathematical foundation for data science and actuarial work.
*/
