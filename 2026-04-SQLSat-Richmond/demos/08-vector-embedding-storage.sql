-- Script 08: Embedding Storage Utilization
-- SQL Saturday Richmond: Vector Embeddings with Ollama

-- Compares actual storage consumed by the VECTOR column
-- across all four embedding tables using DATALENGTH().
USE CourseCatalog;
GO

-- float32 = 4 bytes × 768 dimensions = 3,072 bytes
-- float16 = 2 bytes × 768 dimensions = 1,536 bytes (50% savings!)
SELECT
    TableName,
    Dimensions,
    Precision_Type,
    RowCount_Total,
    BytesPerEmbedding,
    TotalEmbeddingMB
FROM (
    SELECT
        'CourseEmbeddings_768_f32'   AS TableName,
        768                          AS Dimensions,
        'float32'                    AS Precision_Type,
        COUNT(*)                     AS RowCount_Total,
        MIN(DATALENGTH(Embedding))   AS BytesPerEmbedding,
        SUM(DATALENGTH(Embedding))   AS TotalEmbeddingBytes,
        SUM(DATALENGTH(Embedding)) / 1024.0          AS TotalEmbeddingKB,
        SUM(DATALENGTH(Embedding)) / 1024.0 / 1024.0 AS TotalEmbeddingMB
    FROM dbo.CourseEmbeddings_768_f32

    UNION ALL

    SELECT
        'CourseEmbeddings_768_f16',
        768,
        'float16',
        COUNT(*),
        MIN(DATALENGTH(Embedding)),
        SUM(DATALENGTH(Embedding)),
        SUM(DATALENGTH(Embedding)) / 1024.0,
        SUM(DATALENGTH(Embedding)) / 1024.0 / 1024.0
    FROM dbo.CourseEmbeddings_768_f16
) AS storage
ORDER BY Dimensions, Precision_Type DESC;
