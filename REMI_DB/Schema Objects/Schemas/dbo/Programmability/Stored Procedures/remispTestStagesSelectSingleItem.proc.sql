ALTER PROCEDURE [dbo].[remispTestStagesSelectSingleItem] @ID int = null, @Name nvarchar(400) = null, @JobName nvarchar(400) = null
AS
BEGIN
	SELECT ts.Comment,ts.ConcurrencyID,ts.ID,ts.processorder,ts.JobID,ts.LastUser,ts.TestID,ts.TestStageName,ts.TestStageType,  j.jobname, ISNULL(ts.IsArchived,0) AS IsArchived
	FROM TestStages ts
		INNER JOIN Jobs j ON ts.JobID=j.ID
	WHERE (ts.ID = @ID OR @ID IS NULL)
		OR
		(ts.TestStageName = @Name AND j.JobName = @JobName)
END
GO
GRANT EXECUTE ON remispTestStagesSelectSingleItem TO REMI
GO