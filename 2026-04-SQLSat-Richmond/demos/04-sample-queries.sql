-- Script 04: Sample Course Catalog Data
-- SQL Saturday Richmond: Vector Embeddings with Ollama

USE CourseCatalog;
GO

-- BASIC QUERIES
-- View all courses
SELECT * FROM dbo.CourseCatalog;

-- Count total courses
SELECT COUNT(*) AS TotalCourses FROM dbo.CourseCatalog;

-- View courses for a specific term
SELECT CourseID, CourseTitle, Department, Credits
FROM dbo.CourseCatalog
WHERE TermID = 'Fall26';

-- FILTERING BY DEPARTMENT & COLLEGE
-- All Computer Science courses
SELECT CourseTitle, CourseLevel, Credits, Prerequisites
FROM dbo.CourseCatalog
WHERE Department = 'Computer Science'
ORDER BY CourseLevel;

-- All courses in Engineering college
SELECT Department, CourseTitle, CourseLevel
FROM dbo.CourseCatalog
WHERE College = 'Engineering'
ORDER BY Department, CourseLevel;

-- TEXT SEARCH (Traditional keyword matching)
-- Find courses about machine learning or AI
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE CourseDescription LIKE '%machine learning%'
   OR CourseDescription LIKE '%artificial intelligence%'
   OR CourseTitle LIKE '%machine learning%';

-- Courses mentioning "design" in description
SELECT CourseTitle, Department, CourseDescription
FROM dbo.CourseCatalog
WHERE CourseDescription LIKE '%design%'
ORDER BY Department;

-- AGGREGATIONS & ANALYTICS
-- Count courses by department
SELECT Department, COUNT(*) AS CourseCount
FROM dbo.CourseCatalog
GROUP BY Department
ORDER BY CourseCount DESC;

-- Count courses by college and level
SELECT College, CourseLevel, COUNT(*) AS CourseCount
FROM dbo.CourseCatalog
GROUP BY College, CourseLevel
ORDER BY College, CourseLevel;

-- Average credits by course level
SELECT CourseLevel, AVG(Credits) AS AvgCredits
FROM dbo.CourseCatalog
GROUP BY CourseLevel
ORDER BY CourseLevel;

-- Courses per term
SELECT TermID, COUNT(*) AS CourseCount
FROM dbo.CourseCatalog
GROUP BY TermID
ORDER BY TermID;

