ALTER PROCEDURE [dbo].[remispTestStagesSelectList] @JobName nvarchar(400) = null, @TestStageType int = null, @ShowArchived BIT = 0, @JobID INT = 0
AS
	BEGIN
		DECLARE @TrueBit BIT
		DECLARE @FalseBit BIT
		SET @FalseBit = CONVERT(BIT, 0)
		SET @TrueBit = CONVERT(BIT, 1)
		
		SELECT ts.Comment,ts.ConcurrencyID,ts.ID,ts.processorder,ts.JobID,ts.LastUser,ts.TestID,ts.TestStageName,ts.TestStageType,j.jobname, 
			ISNULL(ts.IsArchived, 0) AS IsArchived, dbo.remifnTestStageCanDelete(ts.ID) AS CanDelete
		FROM teststages ts
			INNER JOIN Jobs j ON ts.JobID=j.ID
		WHERE (ts.TestStageType = @TestStageType or @TestStageType is null)
			AND (@ShowArchived = @TrueBit OR (@ShowArchived = @FalseBit AND ISNULL(ts.IsArchived, 0) = @FalseBit))
			AND ISNULL(j.IsActive, 0) = @TrueBit
			AND 
				(
					(@JobID > 0 AND j.ID=@JobID)
					OR
					(@JobName IS NOT NULL AND j.JobName=@JobName)
					OR
					(@JobName IS NULL AND @JobID=0)
				)
		ORDER BY JobName, ProcessOrder
	END
Go
GRANT EXECUTE ON remispTestStagesSelectList TO REMI
GO