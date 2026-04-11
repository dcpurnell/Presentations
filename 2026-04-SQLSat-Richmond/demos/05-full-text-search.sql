-- Script 05: Full-Text Search Index Setup and Queries
-- SQL Saturday Richmond: Vector Embeddings with Ollama

-- SQL Server Full-Text Search:
-- WORD BREAKER: Tokenizes text into words using language-specific rules
--    (handles contractions, possessives, hyphens, etc.)
-- STEMMER: Reduces tokens to root forms (running/runs/ran → run)
--    This powers FORMSOF(INFLECTIONAL, ...) queries
-- STOPWORD FILTERING: Removes common words (the, is, and)
--    Configured via system or custom stoplists per index
-- INVERTED INDEX: Stores word → rows+positions mapping
--    (opposite of B-tree which maps row → values)
--    Position data enables NEAR proximity searches

-- https://learn.microsoft.com/en-us/sql/relational-databases/search/full-text-search?view=sql-server-ver17

USE CourseCatalog;
GO

-- Step 1: Create Full-Text Catalog
-- The catalog is a container for full-text indexes
IF NOT EXISTS (SELECT * FROM sys.fulltext_catalogs WHERE name = 'CourseCatalogFTCatalog')
BEGIN
    CREATE FULLTEXT CATALOG CourseCatalogFTCatalog AS DEFAULT;
    PRINT 'Full-text catalog created successfully.';
END
ELSE
BEGIN
    PRINT 'Full-text catalog already exists.';
END
GO

-- Step 2: Create Full-Text Index
-- Index the most searchable columns: CourseTitle, CourseDescription, Prerequisites
IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.CourseCatalog'))
BEGIN
    CREATE FULLTEXT INDEX ON dbo.CourseCatalog
    (
        CourseDescription LANGUAGE 1033         
    )
    KEY INDEX PK_CourseCatalog_CourseID    -- Must reference the PRIMARY KEY
    ON CourseCatalogFTCatalog
    WITH (CHANGE_TRACKING AUTO, STOPLIST SYSTEM);
    
    PRINT 'Full-text index created successfully.';
END
ELSE
BEGIN
    PRINT 'Full-text index already exists.';
END
GO

-- Step 3: Verify Full-Text Index Status
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    is_enabled,
    change_tracking_state_desc
FROM sys.fulltext_indexes
WHERE object_id = OBJECT_ID('dbo.CourseCatalog');
GO

-- FULL-TEXT SEARCH QUERY EXAMPLES

-- 1. Simple CONTAINS - Exact word or phrase matching
-- WHY: When you need exact phrase matching with word boundaries and stemming support.
-- WHEN: Use for searching specific terms or phrases where word order matters.
-- HOW: Wrap phrases in double quotes for exact matches. Single words don't need quotes.
-- PERFORMANCE: Much faster than LIKE '%pattern%' on large datasets due to inverted index.
-- Find courses containing "machine learning"
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE CONTAINS(CourseDescription, '"machine learning"')
ORDER BY Department;

-- 2. CONTAINS with Boolean Operators (AND, OR, NOT)
-- WHY: Combine multiple search terms with logical operators for complex queries.
-- WHEN: Use AND for narrowing results, OR for broadening, NOT for exclusion.
-- HOW: AND requires all terms present, OR requires at least one, NOT excludes terms.
-- TIP: Boolean operators must be UPPERCASE. Combine with quotes for phrase matching.
-- Courses about both "design" AND "software"
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE CONTAINS(CourseDescription, 'design AND software')
ORDER BY Department;

-- Courses about "statistics" OR "data analysis"
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE CONTAINS(CourseDescription, 'statistics OR "data analysis"')
ORDER BY Department;

-- Courses about "programming" but NOT "web"
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE CONTAINS(CourseDescription, 'programming AND NOT web')
ORDER BY Department;

-- 3. CONTAINS with Proximity Search (NEAR)
-- WHY: Find terms that appear close together without requiring exact phrase matching.
-- WHEN: Use when word order isn't critical but proximity indicates relevance.
-- HOW: NEAR finds words within ~50 characters by default. Use NEAR(term1, term2, distance) for precision.
-- EXAMPLE: "database NEAR design" matches "database design" and "design of databases".
-- Find "machine" near "learning" (within a few words)
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE CONTAINS(CourseDescription, 'machine NEAR learning')
ORDER BY Department;

-- Find "data" near "science" (must be close together)
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE CONTAINS(CourseDescription, 'data NEAR science')
ORDER BY Department;

-- 4. CONTAINS with Prefix Search (Wildcards)
-- WHY: Search word variations without knowing exact endings (plurals, tenses, suffixes).
-- WHEN: Use for word families like program/programming/programmer or analy*/analytics/analysis.
-- HOW: Use asterisk (*) after a prefix. Minimum 4 characters recommended for performance.
-- LIMITATION: Only prefix wildcards supported ("program*" works, "*gram" doesn't).
-- Find courses with words starting with "analy" (analysis, analytics, analytical)
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE CONTAINS(CourseDescription, '"analy*"')
ORDER BY Department;

-- Find courses with words starting with "program" (programming, programmer, program)
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE CONTAINS(CourseDescription, '"program*"')
ORDER BY Department;

-- 5. FREETEXT - Natural language search (less precise)
-- WHY: User-friendly search that handles natural language input without query syntax.
-- WHEN: Use for end-user search boxes, fuzzy matching, or when precision isn't critical.
-- HOW: Breaks input into words, applies stemming, removes noise words, searches all forms.
-- DIFFERENCE: More forgiving than CONTAINS - ignores punctuation, word order, boolean operators.
-- Natural language: find courses about machine learning concepts
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE FREETEXT(CourseDescription, 'machine learning artificial intelligence neural networks')
ORDER BY Department;

-- Natural language: find courses about environmental topics
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE FREETEXT(CourseDescription, 'environment sustainability climate pollution')
ORDER BY Department;

-- 6. FREETEXTTABLE - Ranked search results
-- WHY: Get natural language search results with relevance scoring for better ranking.
-- WHEN: Use for "Google-style" search where you want results sorted by relevance.
-- HOW: Returns a table with [KEY] (primary key) and RANK (0-1000, higher = more relevant).
-- TIP: JOIN on [KEY] column, ORDER BY RANK DESC for best matches first.
-- Search for "data science" with ranking
SELECT TOP 10
    c.CourseTitle,
    c.Department,
    c.CourseDescription,
    ft.RANK AS RelevanceScore
FROM dbo.CourseCatalog c
INNER JOIN FREETEXTTABLE(dbo.CourseCatalog, CourseDescription, 'data science') AS ft
    ON c.CourseID = ft.[KEY]
ORDER BY ft.RANK DESC;

-- Search for "programming" with ranking
SELECT TOP 10
    c.CourseTitle,
    c.Department,
    ft.RANK AS RelevanceScore
FROM dbo.CourseCatalog c
INNER JOIN FREETEXTTABLE(dbo.CourseCatalog, CourseDescription, 'programming') AS ft
    ON c.CourseID = ft.[KEY]
ORDER BY ft.RANK DESC;

-- 7. CONTAINSTABLE - Ranked search with precise matching
-- WHY: Combine the precision of CONTAINS with relevance ranking of table functions.
-- WHEN: Use when you need boolean operators, proximity, wildcards AND relevance scores.
-- HOW: Same syntax as CONTAINS but returns rankable results like FREETEXTTABLE.
-- BEST PRACTICE: Use for complex searches where both precision and ranking matter.
-- Precise search for "machine learning" with ranking
SELECT TOP 10
    c.CourseTitle,
    c.Department,
    c.CourseDescription,
    ct.RANK AS RelevanceScore
FROM dbo.CourseCatalog c
INNER JOIN CONTAINSTABLE(dbo.CourseCatalog, CourseDescription, 'machine AND learning') AS ct
    ON c.CourseID = ct.[KEY]
ORDER BY ct.RANK DESC;

-- Complex boolean search with ranking
SELECT TOP 10
    c.CourseTitle,
    c.Department,
    ct.RANK AS RelevanceScore
FROM dbo.CourseCatalog c
INNER JOIN CONTAINSTABLE(dbo.CourseCatalog, CourseDescription, 
    '(design OR development) AND (software OR application)') AS ct
    ON c.CourseID = ct.[KEY]
ORDER BY ct.RANK DESC;

-- 8. Combined Full-Text and Traditional Filters
-- WHY: Leverage full-text search for text matching while applying structured filters.
-- WHEN: Use when search needs both text relevance AND business logic constraints.
-- HOW: Combine FTS predicates in WHERE clause with standard SQL filters (IN, =, >=, etc).
-- PERFORMANCE: SQL Server can optimize both index types together efficiently.
-- Machine learning courses in Computer Science or Engineering
SELECT CourseTitle, Department, College, CourseDescription
FROM dbo.CourseCatalog
WHERE CONTAINS(CourseDescription, '"machine learning"')
  AND College IN ('Arts & Sciences', 'Engineering')
  AND CourseLevel >= 300
ORDER BY CourseLevel, Department;

-- Graduate-level courses about research
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE CONTAINS(CourseDescription, 'research')
  AND CourseLevel >= 500
ORDER BY Department;

-- 9. Comparison Query: Traditional LIKE vs Full-Text
-- Traditional LIKE (slower, less precise)
PRINT 'Traditional LIKE search:';
SELECT COUNT(*) AS ResultCount
FROM dbo.CourseCatalog
WHERE CourseDescription LIKE '%machine%learning%'
   OR CourseDescription LIKE '%learning%machine%';

-- Full-Text CONTAINS (faster, more intelligent)
PRINT 'Full-Text CONTAINS search:';
SELECT COUNT(*) AS ResultCount
FROM dbo.CourseCatalog
WHERE CONTAINS(CourseDescription, 'machine AND learning');

-- 10. Maintenance Queries
-- Check full-text index population status
SELECT 
    DB_NAME() AS DatabaseName,
    OBJECT_NAME(fti.object_id) AS TableName,
    fc.name AS CatalogName,
    fti.is_enabled,
    fti.change_tracking_state_desc
FROM sys.fulltext_indexes fti
INNER JOIN sys.fulltext_catalogs fc ON fti.fulltext_catalog_id = fc.fulltext_catalog_id
WHERE fti.object_id = OBJECT_ID('dbo.CourseCatalog');

-- Force full-text index repopulation (if needed)
-- This can be used after significant data changes or to refresh the index
ALTER FULLTEXT INDEX ON dbo.CourseCatalog START FULL POPULATION;

-- Start incremental population (after initial full population)
-- This will only index new or changed rows since the last population
ALTER FULLTEXT INDEX ON dbo.CourseCatalog START INCREMENTAL POPULATION;

-- Pause full-text index population
-- This can be useful during heavy data modifications or maintenance windows
ALTER FULLTEXT INDEX ON dbo.CourseCatalog PAUSE POPULATION;

-- Resume full-text index population
ALTER FULLTEXT INDEX ON dbo.CourseCatalog RESUME POPULATION;

