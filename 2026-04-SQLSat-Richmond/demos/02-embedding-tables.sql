-- Script 02: Embedding Tables (1:1 with CourseCatalog)
-- SQL Saturday Richmond: Vector Embeddings with Ollama

-- Two tables: One for float32 & float16. Each has a FK
-- back to dbo.CourseCatalog (Script 01). Separating embeddings
-- keeps the source table fully writable even when a DiskANN
-- vector index is added (preview: vector-indexed tables are
-- read-only on SQL Server 2025 box product).

-- float32: 4 bytes per dimension, up to 1,998 dimensions 
-- float16: 2 bytes per dimension, up to 3,996 dimensions

-- https://learn.microsoft.com/en-us/sql/t-sql/data-types/vector-data-type?view=sql-server-ver17

USE CourseCatalog
GO

-- ============================================================
-- nomic-embed-text (768 dimensions) + float32
-- 4 bytes per dimension = 3,072 bytes per embedding
-- ============================================================
CREATE TABLE dbo.CourseEmbeddings_768_f32 (
    EmbeddingID     INT IDENTITY(1,1) PRIMARY KEY,
    CourseID        INT NOT NULL,
    Embedding       VECTOR(768) NOT NULL,
    CONSTRAINT FK_CourseCatalog_CourseID_f32
        FOREIGN KEY (CourseID) REFERENCES dbo.CourseCatalog (CourseID)
);
GO
CREATE NONCLUSTERED INDEX IX_CE768f32_CourseID
    ON dbo.CourseEmbeddings_768_f32 (CourseID);
GO

-- Enable float16 (still in preview as of CU3)
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO
-- ============================================================
-- nomic-embed-text (768 dimensions) + float16
-- 2 bytes per dimension = 1,536 bytes per embedding
-- ============================================================
CREATE TABLE dbo.CourseEmbeddings_768_f16 (
    EmbeddingID     INT IDENTITY(1,1) PRIMARY KEY,
    CourseID        INT NOT NULL,
    Embedding       VECTOR(768, float16) NOT NULL,
    CONSTRAINT FK_CourseCatalog_CourseID_f16
        FOREIGN KEY (CourseID) REFERENCES dbo.CourseCatalog (CourseID)
);
GO

CREATE NONCLUSTERED INDEX IX_CE768f16_CourseID
    ON dbo.CourseEmbeddings_768_f16 (CourseID);
GO

