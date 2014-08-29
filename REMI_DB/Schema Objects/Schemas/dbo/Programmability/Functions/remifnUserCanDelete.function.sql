SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION dbo.remifnUserCanDelete (@UserName NVARCHAR(255))
RETURNS BIT
AS
BEGIN
	DECLARE @Exists BIT
	SET @UserName = LTRIM(RTRIM(@UserName))
	
	SELECT @Exists = (SELECT DISTINCT 0
		FROM BatchComments
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Batches
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM BatchSpecificTestDurations
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Jobs
		WHERE LTRIM(RTRIM(LastUser))=@UserName	
		UNION
		SELECT DISTINCT 0
		FROM ProductConfiguration
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM ProductConfigValues
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM ProductSettings
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM StationConfigurationUpload
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestExceptions
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestRecords
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Tests
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Tests
		WHERE LTRIM(RTRIM(Owner))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Tests
		WHERE LTRIM(RTRIM(Trainee))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestStages
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestUnits
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TrackingLocations
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT DISTINCT 0
		FROM TrackingLocationsHosts
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT DISTINCT 0
		FROM TrackingLocationsHostsConfiguration
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT DISTINCT 0
		FROM TrackingLocationsHostsConfigValues
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TrackingLocationTypePermissions
		WHERE LTRIM(RTRIM(LastUser))=@UserName OR LTRIM(RTRIM(UserName))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TaskAssignments
		WHERE LTRIM(RTRIM(AssignedTo))=@UserName OR LTRIM(RTRIM(AssignedBy))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TrackingLocationTypes
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM UsersProducts
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM UserTraining
		WHERE LTRIM(RTRIM(UserAssigned))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM ProductConfigurationUpload
		WHERE LTRIM(RTRIM(LastUser))=@UserName)
	
	RETURN ISNULL(@Exists, 1)
END
GO
GRANT EXECUTE ON remifnUserCanDelete TO Remi
GO