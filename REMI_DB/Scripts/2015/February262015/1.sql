/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 2/26/2015 11:14:15 AM

*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO
PRINT N'Altering [dbo].[remispTestStagesSelectList]'
GO
ALTER PROCEDURE [dbo].[remispTestStagesSelectList] @JobName nvarchar(400) = null, @TestStageType int = null, @ShowArchived BIT = 0
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
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO