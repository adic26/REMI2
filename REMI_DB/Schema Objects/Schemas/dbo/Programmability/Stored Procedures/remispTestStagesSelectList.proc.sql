﻿ALTER PROCEDURE [dbo].[remispTestStagesSelectList] @JobName nvarchar(400) = null, @TestStageType int = null, @ShowArchived BIT = 0
AS
	BEGIN
		DECLARE @TrueBit BIT
		DECLARE @FalseBit BIT
		SET @FalseBit = CONVERT(BIT, 0)
		SET @TrueBit = CONVERT(BIT, 1)
		
		if @JobName is not null
		begin
			SELECT ts.Comment,ts.ConcurrencyID,ts.ID,ts.processorder, ts.JobID,ts.LastUser,ts.TestID,ts.TestStageName,ts.TestStageType, j.jobname, 
				ISNULL(ts.IsArchived, 0) AS IsArchived, dbo.remifnTestStageCanDelete(ts.ID) AS CanDelete
			FROM teststages as ts,jobs as j
			where ((ts.jobid = j.id and j.Jobname = @Jobname) or @jobname is null) 
				AND (@ShowArchived = @TrueBit OR (@ShowArchived = @FalseBit AND ISNULL(ts.IsArchived, 0) = @FalseBit))
				AND ISNULL(j.IsActive, 0) = @TrueBit
				AND (ts.TestStageType = @TestStageType or @TestStageType is null)
			order by JobName, ProcessOrder
		end
		else
		begin
			SELECT ts.Comment,ts.ConcurrencyID,ts.ID,ts.processorder,ts.JobID,ts.LastUser,ts.TestID,ts.TestStageName,ts.TestStageType,j.jobname, 
				ISNULL(ts.IsArchived, 0) AS IsArchived, dbo.remifnTestStageCanDelete(ts.ID) AS CanDelete
			FROM teststages as ts, Jobs as j
			where (ts.jobid = j.id and (ts.TestStageType = @TestStageType or @TestStageType is null)) 
				AND (@ShowArchived = @TrueBit OR (@ShowArchived = @FalseBit AND ISNULL(ts.IsArchived, 0) = @FalseBit))
				AND ISNULL(j.IsActive, 0) = @TrueBit
			order by JobName, ProcessOrder
		end
	END
Go
GRANT EXECUTE ON remispTestStagesSelectList TO REMI
GO