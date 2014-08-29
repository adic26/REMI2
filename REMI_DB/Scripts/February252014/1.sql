/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 2/21/2014 9:53:01 AM

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
PRINT N'Altering [dbo].[remispTestsSelectListByType]'
GO
ALTER PROCEDURE [dbo].[remispTestsSelectListByType] @TestType int, @IncludeArchived BIT = 0
AS
BEGIN
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, dbo.remifnTestCanDelete(t.ID) AS CanDelete, t.IsArchived,
		(SELECT TestStageName FROM TestStages WHERE TestID=t.ID) As TestStage, (SELECT JobName FROM Jobs WHERE ID IN (SELECT JobID FROM TestStages WHERE TestID=t.ID)) As JobName
	FROM Tests t
	WHERE TestType = @TestType 
		AND
		(
			(@IncludeArchived = 0 AND ISNULL(t.IsArchived, 0) = 0)
			OR
			(@IncludeArchived = 1)
		)
	ORDER BY TestName;
	
	SELECT t.id, tlt.id, tlt.TrackingLocationTypeName    
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort, Tests as t
	WHERE tlfort.testid = t.id and tlt.ID = tlfort.TrackingLocationtypeID
		AND t.TestType = @TestType
	ORDER BY tlt.TrackingLocationTypeName asc
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTrackingTypesTests]'
GO
ALTER PROCEDURE [dbo].[remispTrackingTypesTests] @TestTypeID INT = 1, @IncludeArchived BIT = 0
AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	SELECT @rows=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + tlt.TrackingLocationTypeName
	FROM  dbo.TrackingLocationTypes tlt
	ORDER BY '],[' +  tlt.TrackingLocationTypeName
	FOR XML PATH('')), 1, 2, '') + ']','[na]')


	SET @query = '
		SELECT *
		FROM
		(
			SELECT CASE WHEN tlft.ID IS NOT NULL THEN 1 ELSE NULL END As Row, t.TestName, tlt.TrackingLocationTypeName, t.testtype
			FROM dbo.TrackingLocationTypes tlt
				LEFT OUTER JOIN dbo.TrackingLocationsForTests tlft ON tlft.TrackingLocationtypeID = tlt.ID
				INNER JOIN dbo.Tests t ON t.ID=tlft.TestID
			WHERE t.TestName IS NOT NULL AND t.TestType=' + CONVERT(VARCHAR, @TestTypeID) + ' AND t.IsArchived=' + CONVERT(VARCHAR, @IncludeArchived) + '
		)r
		PIVOT 
		(
			MAX(row) 
			FOR TrackingLocationTypeName 
				IN ('+@rows+')
		) AS pvt
		ORDER BY TestType ASC, TestName'
	EXECUTE (@query)
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