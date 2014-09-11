ALTER PROCEDURE [dbo].[remispTestStagesSelectSingleItem] @ID int = null, @Name nvarchar(400) = null, @JobName nvarchar(400) = null
AS
BEGIN
	--check that at least one param is set
	if (@ID is null and @Name is not null and @JobName is not null) or (@ID is not null and @Name is not null) 
	BEGIN
		SELECT ts.Comment,ts.ConcurrencyID,ts.ID,ts.processorder,ts.JobID,ts.LastUser,ts.TestID,ts.TestStageName,ts.TestStageType,  j.jobname, ISNULL(ts.IsArchived,0) AS IsArchived
		FROM TestStages ts
			INNER JOIN Jobs j ON ts.JobID=j.ID
		WHERE (ts.ID = @ID or @ID is null) and (ts.TestStageName = @Name and j.jobname = @JobName or @JobName is null)
	END
END
GO
GRANT EXECUTE ON remispTestStagesSelectSingleItem TO REMI
GO