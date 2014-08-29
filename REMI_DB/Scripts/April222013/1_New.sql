/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        ci0000001593275\SQLDeveloper.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 4/17/2013 11:21:46 AM

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
PRINT N'Creating [dbo].[remifnUserCanDelete]'
GO
CREATE FUNCTION dbo.remifnUserCanDelete (@UserName NVARCHAR(255))
RETURNS BIT
AS
BEGIN
	DECLARE @Exists BIT
	SET @UserName = LTRIM(RTRIM(@UserName))
	
	SELECT @Exists = CASE WHEN 
		(SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM BatchComments
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM Batches
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM BatchSpecificTestDurations
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM Jobs
		WHERE LTRIM(RTRIM(LastUser))=@UserName	
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM ProductConfiguration
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM ProductConfigValues
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM ProductManagers
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM ProductSettings
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM StationConfigurationUpload
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 CASE WHEN LTRIM(RTRIM(AssignedTo))=@UserName THEN LTRIM(RTRIM(AssignedTo)) ELSE LTRIM(RTRIM(AssignedBy)) END
		FROM TaskAssignments
		WHERE LTRIM(RTRIM(AssignedTo))=@UserName OR LTRIM(RTRIM(AssignedBy))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM TestExceptions
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM TestRecords
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM Tests
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM TestStages
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM TestUnits
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM TrackingLocations
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM TrackingLocationsHosts
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM TrackingLocationsHostsConfiguration
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM TrackingLocationsHostsConfigValues
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 CASE WHEN LTRIM(RTRIM(UserName))=@UserName THEN LTRIM(RTRIM(UserName)) ELSE LTRIM(RTRIM(LastUser)) END
		FROM TrackingLocationTypePermissions
		WHERE LTRIM(RTRIM(LastUser))=@UserName OR LTRIM(RTRIM(UserName))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM TrackingLocationTypes
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT TOP 1 LTRIM(RTRIM(LastUser))
		FROM ProductConfigurationUpload
		WHERE LTRIM(RTRIM(LastUser))=@UserName) IS NOT NULL THEN CONVERT(BIT, 0) 
		ELSE CONVERT(BIT, 1) END
	
	RETURN @Exists
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[UserTraining]'
GO
CREATE TABLE [dbo].[UserTraining]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[UserName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DateAdded] [datetime] NOT NULL,
[LookupID] [int] NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_UserTraining] on [dbo].[UserTraining]'
GO
ALTER TABLE [dbo].[UserTraining] ADD CONSTRAINT [PK_UserTraining] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetUserTraining]'
GO
CREATE PROCEDURE [dbo].[remispGetUserTraining] @UserName NVARCHAR(255)
AS
BEGIN
	SELECT UserName, DateAdded, Lookups.LookupID, Lookups.[Values] AS TrainingOption, CASE WHEN ID IS NOT NULL THEN CONVERT(BIT,1) ELSE CONVERT(BIT, 0) END AS IsTrained
	FROM Lookups
		LEFT OUTER JOIN UserTraining ON UserTraining.LookupID=Lookups.LookupID AND UserTraining.UserName=@UserName
	WHERE Type='Training'
	ORDER BY Lookups.[Values]
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[UserTraining]'
GO
ALTER TABLE [dbo].[UserTraining] ADD CONSTRAINT [FK_UserTraining_Lookups] FOREIGN KEY ([LookupID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remifnUserCanDelete]'
GO
GRANT EXECUTE ON  [dbo].[remifnUserCanDelete] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispGetUserTraining]'
GO
GRANT EXECUTE ON  [dbo].[remispGetUserTraining] TO [remi]
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