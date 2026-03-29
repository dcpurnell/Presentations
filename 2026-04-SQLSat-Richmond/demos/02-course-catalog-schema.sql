-- ============================================================
-- SQL Saturday Richmond: Course Catalog Demo Dataset
-- Using SQL Server's 2025 Vector Embeddings with Ollama
-- ============================================================
-- Higher ed course catalog — demonstrates vector embeddings
-- and hybrid search (vector similarity + traditional SQL filters)
-- ============================================================

-- Enable float16 preview if needed
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO

-- ============================================================
-- Option A: 768 dimensions (nomic-embed-text) + float32
-- ============================================================
CREATE TABLE dbo.CourseCatalog_768_f32 (
    CourseID            INT IDENTITY(1,1) PRIMARY KEY,
    TermID              VARCHAR(20) NOT NULL,          -- e.g., '2026SP', '2026FA'
    CourseTitle          NVARCHAR(200) NOT NULL,         -- short text, secondary embedding candidate
    CourseDescription   NVARCHAR(MAX) NOT NULL,         -- primary embedding target
    Department          NVARCHAR(100) NOT NULL,         -- e.g., 'Computer Science', 'Mathematics'
    College             NVARCHAR(100) NOT NULL,         -- e.g., 'Arts & Sciences', 'Business'
    CourseLevel         INT NOT NULL,                   -- 100, 200, 300, 400, 500 (graduate)
    Credits             INT NOT NULL,                   -- 3, 4, etc.
    Prerequisites       NVARCHAR(500) NULL,             -- text — semantic prerequisite matching
    DescriptionEmbedding VECTOR(768) NULL               -- nomic-embed-text embedding (float32)
);
GO

-- ============================================================
-- Option B: 768 dimensions (nomic-embed-text) + float16
-- ============================================================
CREATE TABLE dbo.CourseCatalog_768_f16 (
    CourseID            INT IDENTITY(1,1) PRIMARY KEY,
    TermID              VARCHAR(20) NOT NULL,
    CourseTitle          NVARCHAR(200) NOT NULL,
    CourseDescription   NVARCHAR(MAX) NOT NULL,
    Department          NVARCHAR(100) NOT NULL,
    College             NVARCHAR(100) NOT NULL,
    CourseLevel         INT NOT NULL,
    Credits             INT NOT NULL,
    Prerequisites       NVARCHAR(500) NULL,
    DescriptionEmbedding VECTOR(768, float16) NULL      -- nomic-embed-text embedding (float16)
);
GO

-- ============================================================
-- Option C: 1536 dimensions (gte-qwen2-1.5b-instruct) + float32
-- ============================================================
CREATE TABLE dbo.CourseCatalog_1536_f32 (
    CourseID            INT IDENTITY(1,1) PRIMARY KEY,
    TermID              VARCHAR(20) NOT NULL,
    CourseTitle          NVARCHAR(200) NOT NULL,
    CourseDescription   NVARCHAR(MAX) NOT NULL,
    Department          NVARCHAR(100) NOT NULL,
    College             NVARCHAR(100) NOT NULL,
    CourseLevel         INT NOT NULL,
    Credits             INT NOT NULL,
    Prerequisites       NVARCHAR(500) NULL,
    DescriptionEmbedding VECTOR(1536) NULL              -- gte-qwen2 embedding (float32)
);
GO

-- ============================================================
-- Option D: 1536 dimensions (gte-qwen2-1.5b-instruct) + float16
-- ============================================================
CREATE TABLE dbo.CourseCatalog_1536_f16 (
    CourseID            INT IDENTITY(1,1) PRIMARY KEY,
    TermID              VARCHAR(20) NOT NULL,
    CourseTitle          NVARCHAR(200) NOT NULL,
    CourseDescription   NVARCHAR(MAX) NOT NULL,
    Department          NVARCHAR(100) NOT NULL,
    College             NVARCHAR(100) NOT NULL,
    CourseLevel         INT NOT NULL,
    Credits             INT NOT NULL,
    Prerequisites       NVARCHAR(500) NULL,
    DescriptionEmbedding VECTOR(1536, float16) NULL     -- gte-qwen2 embedding (float16)
);
GO

-- ============================================================
-- Demo Progression
-- ============================================================

-- DEMO 1: Pure Vector Search (similarity only)
-- "Find courses most similar to 'Introduction to Data Analytics'"
--
-- SELECT TOP 10
--     CourseTitle, Department, College, CourseLevel,
--     VECTOR_DISTANCE('cosine', DescriptionEmbedding, @searchVector) AS Distance
-- FROM dbo.CourseCatalog_768_f32
-- ORDER BY Distance;

-- DEMO 2: Pure SQL Filter (traditional WHERE)
-- "Show me 300+ level courses in Arts & Sciences"
--
-- SELECT CourseTitle, Department, CourseLevel, Credits
-- FROM dbo.CourseCatalog_768_f32
-- WHERE College = 'Arts & Sciences'
--   AND CourseLevel >= 300;

-- DEMO 3: Hybrid Search (vector + SQL filters combined)
-- "Find courses similar to 'Data Analytics' but only in
--  Arts & Sciences at the 300+ level"
--
-- SELECT TOP 10
--     CourseTitle, Department, College, CourseLevel,
--     VECTOR_DISTANCE('cosine', DescriptionEmbedding, @searchVector) AS Distance
-- FROM dbo.CourseCatalog_768_f32
-- WHERE College = 'Arts & Sciences'
--   AND CourseLevel >= 300
-- ORDER BY Distance;
