-- Script 06: Vector Embeddings Setup
-- SQL Saturday Richmond: Vector Embeddings with Ollama

USE CourseCatalog;
GO

-- Create an external model that points to Nginx reverse proxy for Ollama
CREATE EXTERNAL MODEL ollama768
WITH (
    LOCATION = 'https://model-web:443/api/embed',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'nomic-embed-text'
);
GO

-- Testing the external model by calling AI_GENERATE_EMBEDDINGS function
BEGIN
    DECLARE @result NVARCHAR(MAX);
    SET @result = (SELECT CONVERT(NVARCHAR(MAX), AI_GENERATE_EMBEDDINGS(N'test text' USE MODEL ollama768)))
    SELECT AI_GENERATE_EMBEDDINGS(N'test text' USE MODEL ollama768) AS GeneratedEmbedding

    IF @result IS NOT NULL
        PRINT 'Model test successful. Result: ' + @result;
    ELSE
        PRINT 'Model test failed. No result returned.';
END;
GO

