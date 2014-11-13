BEGIN TRAN
GO
DBCC CHECKIDENT ('Req.Request', RESEED, 1);
go
alter table Req.ReqFieldData ALTER COLUMN Value NVARCHAR(4000) NOT NULL
GO
DECLARE @RequestTypeID INT
DECLARE @TypeID INT
DECLARE @LookupTypeID INT
DECLARE @RequestID INT
DECLARE @RequestNumber NVARCHAR(12)
CREATE TABLE #fields (RequestID INT, RequestNumber NVARCHAR(12), ReqFieldSetupID INT, Name NVARCHAR(150), Value NVARCHAR(400))

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='RequestType'
SELECT @TypeID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='QRA'
SELECT @RequestTypeID = RequestTypeID FROM Req.RequestType WHERE TypeID=@TypeID

SELECT * INTO #Batches FROM Batches WHERE QRANumber LIKE 'QRA-14%' OR QRANumber LIKE 'QRA-13%'

INSERT INTO Req.Request (RequestNumber)
SELECT QRANumber FROM #Batches

DECLARE select_cursor CURSOR FOR SELECT RequestID, RequestNumber FROM Req.Request WHERE RequestNumber LIKE 'QRA-14%' OR RequestNumber LIKE 'QRA-13%'
OPEN select_cursor

FETCH NEXT FROM select_cursor INTO @RequestID, @RequestNumber

WHILE @@FETCH_STATUS = 0
BEGIN	
	INSERT INTO #fields (RequestID, RequestNumber, ReqFieldSetupID, Name, Value)	
	SELECT @RequestID AS RequestID, @RequestNumber AS RequestNumber, rfs.ReqFieldSetupID, rfs.Name, '' AS Value
	FROM Req.ReqFieldSetup rfs
	WHERE RequestTypeID=@RequestTypeID

	FETCH NEXT FROM select_cursor INTO @RequestID, @RequestNumber
END

CLOSE select_cursor
DEALLOCATE select_cursor
	
UPDATE f SET Value=b.TRSStatus FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='Request Status'
UPDATE f SET Value=b.Requestor FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='Requestor'
UPDATE f SET Value=b.ExecutiveSummary FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='Executive Summary'
UPDATE f SET Value=l.[Values] FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber inner join Lookups l on l.LookupID=b.TestCenterLocationID WHERE f.Name='Test Centre Location'
UPDATE f SET Value=l.[Values] FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber inner join Lookups l on l.LookupID=b.DepartmentID WHERE f.Name='Department'
UPDATE f SET Value=b.JobName FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='Requested Test'
UPDATE f SET Value=b.ReportRequiredBy FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='Report Required by'
UPDATE f SET Value=l.[Values] FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber inner join Lookups l on l.LookupID=b.RequestPurpose WHERE f.Name='Purpose'
UPDATE f SET Value=l.[Values] FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber inner join Lookups l on l.LookupID=b.Priority WHERE f.Name='Priority'
UPDATE f SET Value=l.[Values] FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber inner join Lookups l on l.LookupID=b.ProductTypeID WHERE f.Name='Product Type'
UPDATE f SET Value=l.[Values] FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber inner join Lookups l on l.LookupID=b.AccessoryGroupID WHERE f.Name='Accessory Group'
UPDATE f SET Value=b.CPRNumber FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='CPR'
UPDATE f SET Value=b.AssemblyNumber FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='Assembly  Number'
UPDATE f SET Value=b.AssemblyRevision FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='Assembly  Revision'
UPDATE f SET Value=p.productgroupname FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber inner join Products p on p.ID=b.ProductID WHERE f.Name='Product Group'
UPDATE f SET Value=b.PartName FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='Part Name Under Test'
UPDATE f SET Value=b.MechanicalTools FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='Mechanical Tools'
UPDATE f SET Value=b.ExpectedSampleSize FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='Sample Size'
UPDATE f SET Value='http://hwqaweb/pls/trs/data_entry.main?formMode=VIEW&rqId=' + CONVERT(VARCHAR, b.RQID) FROM #fields f INNER JOIN Batches b ON b.QRANumber=f.RequestNumber WHERE f.Name='Request Link'

UPDATE f 
SET Value='https://hwqaweb.rim.net/relab_alpha/webforms_drop.drop_report?printable=false&p_arg=' + CONVERT(VARCHAR, b.RelabJobID)
FROM #fields f 
	INNER JOIN Batches b ON b.QRANumber=f.RequestNumber 
WHERE f.Name='Drop/Tumble Link' AND LOWER(b.JobName) LIKE '%drop%'

UPDATE f 
SET Value='https://hwqaweb.rim.net/relab_alpha/web_tumble_forms.tumble_report?printable=false&p_arg=' + CONVERT(VARCHAR, b.RelabJobID)
FROM #fields f 
	INNER JOIN Batches b ON b.QRANumber=f.RequestNumber 
WHERE f.Name='Drop/Tumble Link' AND LOWER(b.JobName) LIKE '%tumble%'

INSERT INTO Req.ReqFieldData (RequestID, [ReqFieldSetupID], Value)
SELECT RequestID, [ReqFieldSetupID], Value FROM #fields WHERE Value IS NOT NULL
GO
update Req.ReqFieldMapping set IntField='RequestLink', ExtField='Request Link' where IntField='rqid'

delete from Req.ReqFieldMapping where ExtField='Job_ID'

DELETE FROM Req.ReqFieldMapping 
WHERE IntField IN ('AssemblyRevision','AssemblyNumber','PartName','BoardRevisionMinor','MechanicalToolsRevisionMinor',
	'POPNumber','BoardRevision','MechanicalToolsRevisionMajor','PercentComplete','IncludeInTempo','ReportType','HasSpecialInstructions',
	'GetSpecialInstructions','ActualEndDate','ActualStartDate','IsReportRequired')
	
GO
rollback TRAN