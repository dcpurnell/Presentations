-- Script 07: Vector Embeddings Creation
-- SQL Saturday Richmond: Vector Embeddings with Ollama

USE CourseCatalog
GO

-- float32 vector embeddings with 768 dimensions
-- 1000 rows ~1:00 minutes to generate embeddings on MBP M3 Max
insert into CourseEmbeddings_768_f32 (CourseID, Embedding)
select c.CourseID
    ,AI_GENERATE_EMBEDDINGS(c.CourseDescription USE MODEL ollama768) AS embeddings
    from CourseCatalog c

-- Verify data exists and see row count
SELECT COUNT(*) AS TotalEmbeddings_f32
FROM CourseEmbeddings_768_f32;

-- To actually SEE the vector values, convert to string
-- (VECTOR columns don't always display in the results grid)
SELECT TOP 5 
    ce.EmbeddingID,
    ce.CourseID,
    c.CourseTitle,
    CAST(ce.Embedding AS NVARCHAR(MAX)) AS EmbeddingVector_f32
FROM CourseEmbeddings_768_f32 ce
JOIN CourseCatalog c ON ce.CourseID = c.CourseID;

-- float16 vector embeddings with 768 dimensions
-- Preview feature: enable float16 support at the database level before creating float16 VECTOR columns (see Script 02)
-- 1000 rows ~1:00 minutes to generate embeddings on MBP M3 Max
insert into CourseEmbeddings_768_f16 (CourseID, Embedding)
select c.CourseID
    ,AI_GENERATE_EMBEDDINGS(c.CourseDescription USE MODEL ollama768) AS embeddings
    from CourseCatalog c

-- Verify data exists and see row count
SELECT COUNT(*) AS TotalEmbeddings_f16
FROM CourseEmbeddings_768_f16;

-- To actually SEE the vector values, convert to string
SELECT TOP 5 
    ce.EmbeddingID,
    ce.CourseID,
    c.CourseTitle,
    CAST(ce.Embedding AS NVARCHAR(MAX)) AS EmbeddingVector_f16
FROM CourseEmbeddings_768_f16 ce
JOIN CourseCatalog c ON ce.CourseID = c.CourseID;




