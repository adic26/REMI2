ALTER PROCEDURE [dbo].[remispTestStagesSelectListOfNames]
AS
BEGIN
	SELECT DISTINCT ts.TestStageName as Name, ISNULL(ts.IsArchived, 0) AS IsArchived, dbo.remifnTestStageCanDelete(ts.ID) AS CanDelete
	FROM teststages as ts
	WHERE ts.TestStageType IN (1, 3)
	ORDER BY ts.TestStageName
END
GO
GRANT EXECUTE ON remispTestStagesSelectListOfNames TO REMI
GO