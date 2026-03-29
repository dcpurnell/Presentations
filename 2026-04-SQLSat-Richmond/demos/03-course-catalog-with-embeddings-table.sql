-- ============================================================
-- SQL Saturday Richmond: Course Catalog + Separate Embeddings Table
-- Using SQL Server's 2025 Vector Embeddings with Ollama
-- ============================================================
-- PROBLEM: Once you add a vector index (preview) to a table in
--          SQL Server 2025, the table becomes READ-ONLY.
-- SOLUTION: Separate the embeddings into a 1:1 table. Source data
--           stays writable, embeddings can be rebuilt/swapped
--           independently.
-- ============================================================

-- Enable preview features (required for float16 and vector indexes)
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO

-- ============================================================
-- Source Table: CourseCatalog (writable, no vector columns)
-- ============================================================
CREATE TABLE dbo.CourseCatalog (
    CourseID            INT IDENTITY(1,1) PRIMARY KEY,
    TermID              VARCHAR(20) NOT NULL,           -- e.g., '2026SP', '2026FA'
    CourseTitle          NVARCHAR(200) NOT NULL,
    CourseDescription   NVARCHAR(MAX) NOT NULL,
    Department          NVARCHAR(100) NOT NULL,
    College             NVARCHAR(100) NOT NULL,
    CourseLevel         INT NOT NULL,                   -- 100, 200, 300, 400, 500
    Credits             INT NOT NULL,
    Prerequisites       NVARCHAR(500) NULL,
    CreatedDate         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ModifiedDate        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- ============================================================
-- Embeddings Table: 1:1 with CourseCatalog
-- ============================================================
-- Separate table keeps source data writable when vector index
-- is applied. Can be dropped/rebuilt without touching source data.
-- ============================================================
CREATE TABLE dbo.CourseEmbeddings (
    EmbeddingID         INT IDENTITY(1,1) PRIMARY KEY,
    CourseID            INT NOT NULL,
    ModelName           VARCHAR(50) NOT NULL,           -- e.g., 'nomic-embed-text', 'gte-qwen2-1.5b-instruct'
    ModelDimensions     INT NOT NULL,                   -- 768, 1536 — for documentation/validation
    Precision           VARCHAR(10) NOT NULL DEFAULT 'float32', -- 'float32' or 'float16'
    Embedding_768_f32   VECTOR(768) NULL,               -- nomic-embed-text, float32
    Embedding_768_f16   VECTOR(768, float16) NULL,      -- nomic-embed-text, float16
    Embedding_1536_f32  VECTOR(1536) NULL,              -- gte-qwen2, float32
    Embedding_1536_f16  VECTOR(1536, float16) NULL,     -- gte-qwen2, float16
    GeneratedDate       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    SourceHash          VARBINARY(32) NULL,             -- HASHBYTES of CourseDescription for change detection

    CONSTRAINT FK_CourseEmbeddings_CourseCatalog
        FOREIGN KEY (CourseID) REFERENCES dbo.CourseCatalog(CourseID),

    CONSTRAINT UQ_CourseEmbeddings_Course_Model
        UNIQUE (CourseID, ModelName, Precision)          -- one embedding per course/model/precision combo
);
GO

-- ============================================================
-- Index for fast lookups by CourseID
-- ============================================================
CREATE NONCLUSTERED INDEX IX_CourseEmbeddings_CourseID
    ON dbo.CourseEmbeddings (CourseID);
GO

-- ============================================================
-- Strategy 1: Change Detection via Hash
-- ============================================================
-- When generating embeddings, hash the source text. On refresh,
-- compare hashes to skip unchanged rows — avoids re-embedding
-- the entire catalog every time.
-- ============================================================

-- Hash the description when inserting/updating embeddings
-- HASHBYTES('SHA2_256', CAST(CourseDescription AS NVARCHAR(4000)))

-- Find courses that need re-embedding (description changed)
-- SELECT c.CourseID, c.CourseTitle
-- FROM dbo.CourseCatalog c
-- INNER JOIN dbo.CourseEmbeddings e ON c.CourseID = e.CourseID
-- WHERE e.SourceHash <> HASHBYTES('SHA2_256', CAST(c.CourseDescription AS NVARCHAR(4000)));

-- Find courses with no embeddings yet (new courses)
-- SELECT c.CourseID, c.CourseTitle
-- FROM dbo.CourseCatalog c
-- LEFT JOIN dbo.CourseEmbeddings e ON c.CourseID = e.CourseID
-- WHERE e.EmbeddingID IS NULL;

-- ============================================================
-- Strategy 2: Timestamp Comparison
-- ============================================================
-- Compare CourseCatalog.ModifiedDate against
-- CourseEmbeddings.GeneratedDate. If source is newer, re-embed.
-- Simpler than hashing but requires discipline on ModifiedDate.
-- ============================================================

-- Find stale embeddings (source modified after embedding generated)
-- SELECT c.CourseID, c.CourseTitle,
--        c.ModifiedDate AS SourceModified,
--        e.GeneratedDate AS EmbeddingGenerated
-- FROM dbo.CourseCatalog c
-- INNER JOIN dbo.CourseEmbeddings e ON c.CourseID = e.CourseID
-- WHERE c.ModifiedDate > e.GeneratedDate;

-- ============================================================
-- Strategy 3: Drop and Rebuild (full refresh)
-- ============================================================
-- For smaller catalogs or periodic batch refreshes:
-- 1. Drop vector index (if exists)
-- 2. TRUNCATE dbo.CourseEmbeddings
-- 3. Re-generate all embeddings via Ollama
-- 4. Recreate vector index
-- Pro: Simple, no drift. Con: Downtime, reprocessing cost.
-- ============================================================

-- ============================================================
-- Hybrid Search Query (joining both tables)
-- ============================================================
-- "Find courses similar to 'Data Analytics' in Arts & Sciences, 300+ level"
--
-- DECLARE @searchVector VECTOR(768);
-- -- (populate @searchVector from Ollama API call)
--
-- SELECT TOP 10
--     c.CourseTitle,
--     c.Department,
--     c.College,
--     c.CourseLevel,
--     c.Credits,
--     VECTOR_DISTANCE('cosine', e.Embedding_768_f32, @searchVector) AS Distance
-- FROM dbo.CourseCatalog c
-- INNER JOIN dbo.CourseEmbeddings e
--     ON c.CourseID = e.CourseID
--    AND e.ModelName = 'nomic-embed-text'
--    AND e.Precision = 'float32'
-- WHERE c.College = 'Arts & Sciences'
--   AND c.CourseLevel >= 300
-- ORDER BY Distance;
