BEGIN TRAN
GO
CREATE TABLE [dbo].[JobAccess]
(
[JobAccessID] [int] NOT NULL IDENTITY(1, 1),
[JobID] [int] NOT NULL,
[LookupID] [int] NOT NULL
)
GO
-- Constraints and Indexes

ALTER TABLE [dbo].[JobAccess] ADD CONSTRAINT [PK_JobAccess] PRIMARY KEY CLUSTERED  ([JobAccessID])
GO
-- Foreign Keys

ALTER TABLE [dbo].[JobAccess] ADD CONSTRAINT [FK_JobAccess_Jobs] FOREIGN KEY ([JobID]) REFERENCES [dbo].[Jobs] ([ID])
GO
ALTER TABLE [dbo].[JobAccess] ADD CONSTRAINT [FK_JobAccess_Lookups] FOREIGN KEY ([LookupID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
DECLARE @LookupID INT

SELECT @LookupID=LookupID FROM Lookups WHERE LookupTypeID IN (SELECT LookupTypeID FROM LookupType WHERE Name='Department') AND [Values]='Product Validation'

insert into JobAccess (JobID, LookupID)
select id, @LookupID
from jobs
WHERE IsActive=1
go
ALTER PROCEDURE [dbo].remispJobsList @UserID INT
AS
	BEGIN
		DECLARE @TrueBit BIT
		SET @TrueBit = CONVERT(BIT, 1)
		
		SELECT ja.JobID
		INTO #JobAccess
		FROM UserDetails ud 
			INNER JOIN Lookups l ON l.LookupID=ud.LookupID
			INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID AND lt.Name='Department'
			INNER JOIN JobAccess ja ON ja.LookupID=ud.LookupID
		WHERE ud.UserID=@UserID
		
		SELECT j.ID, j.JobName, j.IsActive, j.ContinueOnFailures, j.LastUser, j.NoBSN, j.TechnicalOperationsTest, j.ProcedureLocation, j.MechanicalTest,
			j.WILocation, j.OperationsTest, j.Comment
		FROM Jobs j
		WHERE j.IsActive=@TrueBit AND j.ID IN (SELECT JobID FROM #JobAccess)
		ORDER BY j.JobName
		
		DROP TABLE #JobAccess
	END
Go
GRANT EXECUTE ON remispJobsList TO REMI
GO
ALTER TABLE [Req].[ReqFieldSetup] ADD [Category] NVARCHAR(100) NULL
GO
UPDATE Req.[ReqFieldSetup] SET Category='Request'
go
ALTER TABLE [Req].[ReqFieldSetup] ALTER COLUMN [Category] NVARCHAR(100) NOT NULL
GO
ALTER PROCEDURE [Req].[RequestFieldSetup] @RequestTypeID INT, @IncludeArchived BIT = 0, @RequestNumber NVARCHAR(12) = NULL
AS
BEGIN
	DECLARE @RequestID INT
	DECLARE @RequestType NVARCHAR(150)
	SET @RequestID = 0
	SET @IncludeArchived=0

	SELECT @RequestType=lrt.[values] FROM Req.RequestType rt INNER JOIN Lookups lrt ON lrt.LookupID=rt.TypeID WHERE rt.RequestTypeID=@RequestTypeID

	IF (@RequestNumber IS NOT NULL)
		BEGIN
			SELECT @RequestID = RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber
		END
	ELSE
		BEGIN
			SELECT @RequestNumber = REPLACE(RequestNumber, @RequestType + '-' + Right(Year(getDate()),2) + '-', '') + 1 
			FROM Req.Request 
			WHERE RequestNumber LIKE @RequestType + '-' + Right(Year(getDate()),2) + '-%'
			
			IF (LEN(@RequestNumber) < 4)
			BEGIN
				SET @RequestNumber = REPLICATE('0', 4-LEN(@RequestNumber)) + @RequestNumber
			END
		
			IF (@RequestNumber IS NULL)
				SET @RequestNumber = '0001'
		
			SET @RequestNumber = @RequestType + '-' + Right(Year(getDate()),2) + '-' + @RequestNumber
		END

	SELECT rfs.ReqFieldSetupID, @RequestType AS RequestType, rfs.Name, lft.[Values] AS FieldType, rfs.FieldTypeID, 
			lvt.[Values] AS ValidationType, rfs.FieldValidationID, ISNULL(rfs.IsRequired, 0) AS IsRequired, rfs.DisplayOrder, 
			rfs.ColumnOrder, ISNULL(rfs.Archived, 0) AS Archived, rfs.Description, rfs.OptionsTypeID, @RequestTypeID AS RequestTypeID,
			@RequestNumber AS RequestNumber, @RequestID AS RequestID, rfd.Value, rfm.IntField, rfm.ExtField,
			CASE WHEN rfm.ID IS NOT NULL THEN 1 ELSE 0 END AS InternalField,
			CASE WHEN @RequestID = 0 THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS NewRequest, Req.RequestType.IsExternal AS IsFromExternalSystem, rfs.Category
	FROM Req.RequestType
		INNER JOIN Lookups lrt ON lrt.LookupID=Req.RequestType.TypeID
		INNER JOIN Req.ReqFieldSetup rfs ON rfs.RequestTypeID=Req.RequestType.RequestTypeID                  
		INNER JOIN Lookups lft ON lft.LookupID=rfs.FieldTypeID
		LEFT OUTER JOIN Lookups lvt ON lvt.LookupID=rfs.FieldValidationID
		LEFT OUTER JOIN Req.ReqFieldSetupRole ON Req.ReqFieldSetupRole.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.Request ON RequestNumber=@RequestNumber
		LEFT OUTER JOIN Req.ReqFieldData rfd ON rfd.ReqFieldSetupID=rfs.ReqFieldSetupID AND rfd.RequestID=Req.Request.RequestID
		LEFT OUTER JOIN Req.ReqFieldMapping rfm ON rfm.RequestTypeID=Req.RequestType.RequestTypeID AND rfm.ExtField=rfs.Name AND ISNULL(rfm.IsActive, 0) = 1
	WHERE (lrt.[Values] = @RequestType) AND
		(
			(@IncludeArchived = 1)
			OR
			(@IncludeArchived = 0 AND ISNULL(rfs.Archived, 0) = 0)
		)
	ORDER BY Category, ISNULL(rfs.DisplayOrder, 0) ASC
END
GO
GRANT EXECUTE ON [Req].[RequestFieldSetup] TO REMI
GO
create PROCEDURE [dbo].[remispGetJobAccess] @JobID INT = 0
AS
BEGIN
	SELECT ja.JobAccessID, j.JobName, l.[Values] As Department
	FROM JobAccess ja
		INNER JOIN Jobs j ON j.ID=ja.JobID
		INNER JOIN Lookups l ON l.LookupID=ja.LookupID
	WHERE (@JobID > 0 AND ja.JobID=@JobID) OR (@JobID = 0)
	ORDER BY j.JobName
END
GO
GRANT EXECUTE ON [dbo].[remispGetJobAccess] TO REMI
GO
ALTER PROCEDURE [Req].[RequestGet] @RequestTypeID INT, @Department NVARCHAR(150)
AS
BEGIN
	DECLARE @Count INT
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rfm.IntField
		FROM Req.ReqFieldSetup rfs
			INNER JOIN Req.ReqFieldMapping rfm ON rfm.ExtField = rfs.Name AND rfm.RequestTypeID=@RequestTypeID
		WHERE rfs.RequestTypeID=@RequestTypeID
		ORDER BY '],[' +  rfm.IntField
		FOR XML PATH('')), 1, 2, '') + ']','[na]')
		
	SELECT @Count = COUNT(*)
	FROM Req.Request r
		INNER JOIN Req.ReqFieldData rfd ON rfd.RequestID=r.RequestID
		INNER JOIN Req.ReqFieldSetup rfs ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
		INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
	WHERE rt.RequestTypeID=@RequestTypeID

	IF (@Count > 0)
	BEGIN
		SET @sql = 'SELECT RequestID, RequestNumber AS RequestNumber, [RequestStatus] AS STATUS, [ProductGroup] AS PRODUCT, [ProductType] AS PRODUCTTYPE,
			[AccessoryGroup] AS ACCESSORYGROUPNAME, [TestCenterLocation] AS TESTCENTER, [Department] AS DEPARTMENT, [SampleSize] AS SAMPLESIZE,
			[RequestedTest] AS Job, [RequestPurpose] AS PURPOSE, [CPRNumber] AS CPR, CONVERT(DateTime, REPLACE([ReportRequiredBy], ''-'','' '')) AS [Report Required By],
			[Priority] AS PRIORITY, [Requestor] AS REQUESTOR, CONVERT(DateTime, REPLACE([DateCreated], ''-'','' '')) AS CRE_DATE
			FROM 
				(
				SELECT r.RequestID, r.RequestNumber, rfd.Value, rfm.IntField
				FROM Req.Request r
					INNER JOIN Req.ReqFieldData rfd ON rfd.RequestID=r.RequestID
					INNER JOIN Req.ReqFieldSetup rfs ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
					INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
					INNER JOIN Req.ReqFieldMapping rfm ON rfm.ExtField = rfs.Name
				WHERE rt.RequestTypeID=' + CONVERT(NVARCHAR, @RequestTypeID) + '
				) req PIVOT (MAX(Value) FOR IntField IN (' + @rows + ')) AS pvt
			WHERE [Department] = ''' + @Department + ''' AND
				[RequestStatus] IN (''Submitted'',''PM Review'',''Assigned'') '

		PRINT @sql
		EXEC (@sql)
	END
END
GO
GRANT EXECUTE ON [Req].[RequestGet] TO REMI
GO
create PROCEDURE remispMenu
AS
BEGIN
	SELECT m.Name, m.Url, m.MenuID
	FROM Menu m
	ORDER BY m.Name
END
GO
GRANT EXECUTE ON remispMenu TO REMI
GO
ALTER PROCEDURE remispMenuAccessByDepartment @Name NVARCHAR(150) = NULL, @DepartmentID INT = NULL
AS
BEGIN
	SELECT m.Name, l.[Values] AS Department, m.Url, m.MenuID, md.MenuDepartmentID
	FROM Menu m
		INNER JOIN MenuDepartment md ON m.MenuID=md.MenuID
		INNER JOIN Lookups l ON l.LookupID=md.DepartmentID
	WHERE (md.DepartmentID = @DepartmentID OR ISNULL(@DepartmentID, 0) = 0)
		AND (m.Name=@Name OR LTRIM(RTRIM(ISNULL(@Name, '')))  = '')
	ORDER BY l.[Values], m.Name
END
GO
GRANT EXECUTE ON remispMenuAccessByDepartment TO REMI
GO
update Req.ReqFieldSetup set category='Scan' where Name like '%requested%'
GO
INSERT INTO Jobs (JobName, WILocation, Comment,LastUser,OperationsTest,MechanicalTest,TechnicalOperationsTest,ProcedureLocation,IsActive,NoBSN,ContinueOnFailures)
values ('WLAN', NULL, NULL, 'ogaudreault',0,0,0, NULL,1,0,0)
go
DECLARE @RFLookupID INT
SELECT @RFLookupID=LookupID FROM Lookups WHERE LookupTypeID IN (SELECT LookupTypeID FROM LookupType WHERE Name='Department') AND [Values]='RF Engineering'
insert into JobAccess (JobID, LookupID)
select id, @RFLookupID
from jobs
WHERE JobName='WLAN'
go
rollback TRAN