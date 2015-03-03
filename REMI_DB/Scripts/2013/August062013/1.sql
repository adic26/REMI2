begin tran
go
ALTER procedure [dbo].[remispExceptionSearch] @ProductID INT = 0, @AccessoryGroupID INT = 0, @ProductTypeID INT = 0, @TestID INT = 0, @TestStageID INT = 0, @JobName NVARCHAR(400) = NULL
AS
BEGIN
	DECLARE @JobID INT
	SELECT @JobID = ID FROM Jobs WHERE JobName=@JobName

	select *
	from 
	(
		select ROW_NUMBER() over (order by p.ProductGroupName desc)as row, pvt.ID, null as batchunitnumber, pvt.[ReasonForRequest], p.ProductGroupName,
		(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
		(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, 
		t.TestName,pvt.TestStageID, pvt.TestUnitID,
		(select top 1 LastUser from TestExceptions WHERE ID=pvt.ID) AS LastUser,
		(select top 1 ConcurrencyID from TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID,
		pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName
		FROM vw_ExceptionsPivoted as pvt
			LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
			LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
			LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
			LEFT OUTER JOIN Products p ON p.ID=pvt.ProductID
		WHERE (
				(pvt.[ProductID]=@ProductID) 
				OR
				(@ProductID = 0)
			)
			AND
			(
				(pvt.AccessoryGroupID = @AccessoryGroupID) 
				OR
				(@AccessoryGroupID = 0)
			)
			AND
			(
				(pvt.ProductTypeID = @ProductTypeID) 
				OR
				(@ProductTypeID = 0)
			)
			AND
			(
				(pvt.Test = @TestID) 
				OR
				(@TestID = 0)
			)
			AND
			(
				(pvt.TestStageID = @TestStageID) 
				OR
				(@TestStageID = 0 And @JobID IS NULL OR @JobID = 0)
				OR
				(@JobID > 0 And @TestStageID = 0 AND pvt.TestStageID IN (SELECT ID FROM TestStages WHERE JobID=@JobID))
			)
			
	) as exceptionResults
	ORDER BY TestName
END
GO
GRANT EXECUTE ON remispExceptionSearch TO REMI
GO
ALTER PROCEDURE [Relab].[remispResultsSummary] @BatchID INT
AS
BEGIN
	SELECT r.ID, ts.TestStageName, t.TestName, tu.BatchUnitNumber, CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail,
		ISNULL((SELECT TOP 1 1 FROM Relab.ResultsMeasurements WHERE ResultID=r.ID),0) AS HasMeasurements
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
	WHERE tu.BatchID=@BatchID
	ORDER BY tu.BatchUnitNumber, ts.TestStageName, t.TestName
END
GO
GRANT EXECUTE ON [Relab].[remispResultsSummary] TO Remi
GO

ALTER PROCEDURE [dbo].[remispTestExceptionsDeleteTestUnitException]
	@QRANumber nvarchar(11),
	@BatchUnitNumber int,
	@TestName nvarchar(400),
	@TestStageName nvarchar(400) = null,
	@LastUser nvarchar(255),
	@TestUnitID INT = NULL
AS
BEGIN	
	DECLARE @TestStageID INT
	DECLARE @TestID INT
	
	IF (@TestUnitID IS NULL)
		SET @TestUnitID = (SELECT ID FROM TestUnits WHERE BatchID = (SELECT ID FROM Batches WHERE QRANumber = @QRAnumber) and BatchUnitNumber = @BatchUnitNumber)
		
	SET @TestID = (SELECT ID FROM Tests WHERE TestName=@TestName)	
	
	SET @TestStageID = (SELECT ts.ID 
						FROM TestStages ts
							INNER JOIN Jobs j ON j.ID = ts.JobID
							INNER JOIN Batches b ON b.JobName = j.JobName
							INNER JOIN TestUnits tu ON tu.BatchID = b.ID
						WHERE tu.ID=@TestUnitID AND ts.TestStageName = @TestStageName)

	DECLARE @txID int = (SELECT ID 
						FROM vw_ExceptionsPivoted 
						WHERE TestUnitID = @TestUnitID AND Test = @TestID
							AND 
							(
								TestStageID = @TestStageID 
								OR
								(
									@TestStageId IS NULL AND TestStageID IS NULL
								)
							)
						)
	
	--set the deleting user
	UPDATE TestExceptions SET LastUser = @LastUser WHERE TestExceptions.ID = @txid
	
	--finally delete the item
	DELETE FROM TestExceptions WHERE TestExceptions.ID = @txid
	
	RETURN @txid
END
GO
GRANT EXECUTE ON remispTestExceptionsDeleteTestUnitException TO REMI
GO






Insert into Lookups (LookupID, Type, [Values], IsActive) values (3216, 'FunctionalMatrix', 'QWERTY Keypad',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3217, 'FunctionalMatrix', 'Peripheral Keys',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3218, 'FunctionalMatrix', 'Navigation Keys',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3219, 'FunctionalMatrix', 'Trackball / Pad',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3220, 'FunctionalMatrix', 'SIM Card',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3221, 'FunctionalMatrix', 'SD Card',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3222, 'FunctionalMatrix', 'SD Switch',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3223, 'FunctionalMatrix', 'Headset',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3224, 'FunctionalMatrix', 'Holster',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3225, 'FunctionalMatrix', 'Magnetometer',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3226, 'FunctionalMatrix', 'Accelerometer',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3227, 'FunctionalMatrix', 'NFC SWP / eMMC',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3228, 'FunctionalMatrix', 'NFC RF Loopback',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3229, 'FunctionalMatrix', 'Flip / Slider',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3230, 'FunctionalMatrix', 'Touch / Tactile',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3231, 'FunctionalMatrix', 'Light Sensor',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3232, 'FunctionalMatrix', 'Proximity Sensor',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3233, 'FunctionalMatrix', 'Torchlight',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3234, 'FunctionalMatrix', 'Camera',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3235, 'FunctionalMatrix', 'Vibrator',1)
Insert into Lookups (LookupID, Type, [Values], IsActive) values (3236, 'FunctionalMatrix', 'Tricolor LED',1)
go
rollback tran