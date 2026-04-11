-- Script 09: Vector Distance Queries
-- SQL Saturday Richmond: Vector Embeddings with Ollama

USE CourseCatalog;
GO

-- Example 1: COSINE Distance (RECOMMENDED)
-- Search for courses related to AI and machine learning using COSINE distance
-- - the preferred method for semantic similarity.
-- This example:
--      Generates embeddings for a search query about AI/ML topics
--      Searches the 768-dimension float32 embedding table
--      Returns top 20 most similar courses based on vector angle
--      Lower cosine distance = more similar (0=identical, 2=opposite)
-- ============================================================

-- Sample text: Looking for courses about AI, machine learning, and neural networks
DECLARE @searchText NVARCHAR(500) = N'artificial intelligence machine learning neural networks deep learning predictive models';
DECLARE @embedding768 VECTOR(768) = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL ollama768);

SELECT TOP 20
    c.CourseTitle,
    c.Department,
    c.CourseLevel,
    VECTOR_DISTANCE('cosine', ce.Embedding, @embedding768) AS CosineDist,
    c.CourseDescription
FROM dbo.CourseEmbeddings_768_f32 ce
JOIN dbo.CourseCatalog c ON ce.CourseID = c.CourseID
ORDER BY VECTOR_DISTANCE('cosine', ce.Embedding, @embedding768) ASC;
GO

-- Example 2: EUCLIDEAN Distance
-- Search using EUCLIDEAN distance - measures straight-line distance in vector space.
-- This example:
--      Uses the same AI/ML search query
--      Searches the 768-dimension float32 embedding table
--      Returns top 20 most similar courses based on Euclidean distance
--      Lower distance = more similar

-- Sample text: Looking for courses about AI, machine learning, and neural networks
DECLARE @searchText NVARCHAR(500) = N'artificial intelligence machine learning neural networks deep learning predictive models';
DECLARE @embedding768 VECTOR(768) = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL ollama768);

SELECT TOP 20
    c.CourseTitle,
    c.Department,
    c.CourseLevel,
    VECTOR_DISTANCE('euclidean', ce.Embedding, @embedding768) AS EuclideanDist,
    c.CourseDescription
FROM dbo.CourseEmbeddings_768_f32 ce
JOIN dbo.CourseCatalog c ON ce.CourseID = c.CourseID
ORDER BY VECTOR_DISTANCE('euclidean', ce.Embedding, @embedding768) ASC;
GO

-- Example 3: DOT Product Distance
-- Search using DOT product - measures the dot product between vectors.
-- This example:
--      Uses the same AI/ML search query
--      Searches the 768-dimension float32 embedding table
--      IMPORTANT: DOT product works differently - HIGHER values = MORE similar
--      Results are sorted DESCENDING (opposite of cosine/euclidean)

-- Sample text: Looking for courses about AI, machine learning, and neural networks
DECLARE @searchText NVARCHAR(500) = N'artificial intelligence machine learning neural networks deep learning predictive models';
DECLARE @embedding768 VECTOR(768) = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL ollama768);

-- Note: With DOT product, HIGHER values indicate MORE similarity
-- So we order DESCENDING (unlike cosine/euclidean)
SELECT TOP 20
    c.CourseTitle,
    c.Department,
    c.CourseLevel,
    VECTOR_DISTANCE('dot', ce.Embedding, @embedding768) AS DotProductDist,
    c.CourseDescription
FROM dbo.CourseEmbeddings_768_f32 ce
JOIN dbo.CourseCatalog c ON ce.CourseID = c.CourseID
ORDER BY VECTOR_DISTANCE('dot', ce.Embedding, @embedding768) DESC;
GO

