begin tran
go
insert into aspnet_Permissions values ('d05ba7ba-6bec-4b90-b79f-d44a060fe568','HasAdminReadOnlyAuthority','892170d7-f95a-4ae1-a7e7-c1994d392790')
go
insert into aspnet_PermissionsInRoles (RoleID,PermissionID) values ('E56DA858-572E-4F34-A3D9-89411321953C','d05ba7ba-6bec-4b90-b79f-d44a060fe568')
go
ALTER PROCEDURE [dbo].[remispTrackingTypesTests] @TestTypeID INT = 1
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
			WHERE t.TestName IS NOT NULL AND t.TestType=' + CONVERT(VARCHAR, @TestTypeID) + '
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
GRANT EXECUTE ON remispTrackingTypesTests TO REMI
GO

ALTER PROCEDURE Relab.[remispGetAllResultsByQRAStage] @BatchID INT, @TestStageID INT
AS
BEGIN
	SELECT r.ID, j.JobName + '-' + ts.TestStageName AS TestStageName, t.TestName, tu.BatchUnitNumber, CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail, t.ID As TestID, ts.ID As TestStageID,
		ISNULL((SELECT MAX(ISNULL(rxml.VerNum,0)) FROM Relab.ResultsXML rxml WHERE rxml.ResultID=r.ID),0) AS VerNum
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
		INNER JOIN Jobs j ON j.ID=ts.JobID
	WHERE tu.BatchID=@BatchID AND ts.ID=@TestStageID
	ORDER BY tu.BatchUnitNumber, ts.TestStageName, t.TestName
END
GO
GRANT EXECUTE ON Relab.[remispGetAllResultsByQRAStage] TO REMI
GO
rollback tran
go