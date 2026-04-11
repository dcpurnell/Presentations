-- Script 12: DBA Considerations
-- SQL Saturday Richmond: Vector Embeddings with Ollama

USE CourseCatalog;
GO

-- Storage comparison: show actual sizes
-- (Run after populating embeddings)
EXEC sp_spaceused 'dbo.CourseEmbeddings_768_f32';
GO

-- Check vector index metadata
SELECT
    i.name AS index_name,
    i.type_desc,
    OBJECT_NAME(i.object_id) AS table_name
FROM sys.indexes i
WHERE i.type_desc LIKE '%VECTOR%';
GO

-- Check query performance for vector searches
SELECT TOP 10
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_us,
    qs.execution_count,
    qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
    SUBSTRING(qt.text, 1, 200) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qt.text LIKE '%VECTOR%'
ORDER BY avg_elapsed_us DESC;
GO
