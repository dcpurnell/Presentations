-- Script 01: Main Course Catalog Table
-- SQL Saturday Richmond: Vector Embeddings with Ollama

-- Single source-of-truth for course data. No embedding columns,
-- those live in the 1:1 embedding tables (Script 02).
-- This table stays fully writable regardless of vector indexes.

CREATE DATABASE [CourseCatalog]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'CourseCatalog', 
    FILENAME = N'/var/opt/mssql/data/CourseCatalog.mdf' , 
    SIZE = 8192KB , 
    FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'CourseCatalog_log', 
    FILENAME = N'/var/opt/mssql/data/CourseCatalog_log.ldf' , 
    SIZE = 8192KB , 
    FILEGROWTH = 65536KB )
GO

USE CourseCatalog;
GO

CREATE TABLE dbo.CourseCatalog (
    CourseID            INT IDENTITY(1,1) NOT NULL,
    TermID              VARCHAR(10) NOT NULL,           -- e.g., 'Fall26', 'Spring27'
    CourseTitle         VARCHAR(200) NOT NULL,          -- short text, secondary embedding candidate
    CourseDescription   VARCHAR(500) NOT NULL,          -- primary embedding target
    Department          VARCHAR(100) NOT NULL,          -- e.g., 'Computer Science', 'Mathematics'
    College             VARCHAR(100) NOT NULL,          -- e.g., 'Arts & Sciences', 'Business'
    CourseLevel         INT NOT NULL,                   -- 100, 200, 300, 400, 500 (graduate)
    Credits             INT NOT NULL,                   -- 3, 4, etc.
    Prerequisites       VARCHAR(500) NULL,              -- text — semantic prerequisite matching
    CONSTRAINT PK_CourseCatalog_CourseID PRIMARY KEY CLUSTERED (CourseID)
);
GO
/*
-- Lab clean up
-- close connections to the database before dropping
USE master;
GO
ALTER DATABASE CourseCatalog SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE CourseCatalog;
GO
*/