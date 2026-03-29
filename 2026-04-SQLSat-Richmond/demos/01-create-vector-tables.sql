-- ============================================================
-- SQL Saturday Richmond: Vector Column DDL Comparison
-- Using SQL Server's 2025 Vector Embeddings with Ollama
-- ============================================================

-- Enable float16 (still in preview as of CU1)
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO

-- ============================================================
-- nomic-embed-text (768 dimensions)
-- ============================================================

-- float32 (default) — 4 bytes per dimension = 3,072 bytes per embedding
CREATE TABLE dbo.Embeddings_768_f32 (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    SourceText  NVARCHAR(MAX) NOT NULL,
    Embedding   VECTOR(768) NOT NULL
);
GO

-- float16 (half precision) — 2 bytes per dimension = 1,536 bytes per embedding
CREATE TABLE dbo.Embeddings_768_f16 (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    SourceText  NVARCHAR(MAX) NOT NULL,
    Embedding   VECTOR(768, float16) NOT NULL
);
GO

-- ============================================================
-- gte-qwen2-1.5b-instruct (1536 dimensions)
-- ============================================================

-- float32 (default) — 4 bytes per dimension = 6,144 bytes per embedding
CREATE TABLE dbo.Embeddings_1536_f32 (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    SourceText  NVARCHAR(MAX) NOT NULL,
    Embedding   VECTOR(1536) NOT NULL
);
GO

-- float16 (half precision) — 2 bytes per dimension = 3,072 bytes per embedding
CREATE TABLE dbo.Embeddings_1536_f16 (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    SourceText  NVARCHAR(MAX) NOT NULL,
    Embedding   VECTOR(1536, float16) NOT NULL
);
GO

-- ============================================================
-- Storage Comparison (bytes per embedding column per row)
-- ============================================================
-- | Model              | Dimensions | float32  | float16  |
-- |--------------------|-----------|----------|----------|
-- | nomic-embed-text   |       768 |    3,072 |    1,536 |
-- | gte-qwen2-1.5b     |     1,536 |    6,144 |    3,072 |
-- ============================================================
-- Note: 768 x float32 (3,072) = 1536 x float16 (3,072)
--       Same storage, different precision/dimension tradeoff!
-- ============================================================

-- Max dimensions: 1,998 (float32), 3,996 (float16)
-- float16 requires: ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON
