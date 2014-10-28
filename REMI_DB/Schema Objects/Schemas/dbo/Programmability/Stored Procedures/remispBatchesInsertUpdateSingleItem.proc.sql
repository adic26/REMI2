ALTER PROCEDURE [dbo].[remispBatchesInsertUpdateSingleItem]
	@ID int OUTPUT,
	@QRANumber nvarchar(11),
	@Priority NVARCHAR(150) = 'NotSet', 
	@BatchStatus int, 
	@JobName nvarchar(400),
	@TestStageName nvarchar(255)=null,
	@ProductGroupName nvarchar(800),
	@ProductType nvarchar(800),
	@AccessoryGroupName nvarchar(800) = null,
	@Comment nvarchar(1000) = null,
	@TestCenterLocation nvarchar(400),
	@RequestPurpose nvarchar(200),
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@testStageCompletionStatus int = null,
	@requestor nvarchar(500) = null,
	@unitsToBeReturnedToRequestor bit = null,
	@expectedSampleSize int = null,
	@relabJobID int = null,
	@reportApprovedDate datetime = null,
	@reportRequiredBy datetime = null,
	@rqID int = null,
	@partName nvarchar(500) = null,
	@assemblyNumber nvarchar(500) = null,
	@assemblyRevision nvarchar(500) = null,
	@trsStatus nvarchar(500) = null,
	@cprNumber nvarchar(500) = null,
	@hwRevision nvarchar(500) = null,
	@pmNotes nvarchar(500) = null,
	@IsMQual bit = 0,
	@MechanicalTools NVARCHAR(10),
	@RequestPurposeID int = 0,
	@PriorityID INT = 0,
	@DepartmentID INT = 0,
	@Department NVARCHAR(150) = NULL
	AS
	DECLARE @ProductID INT
	DECLARE @ProductTypeID INT
	DECLARE @AccessoryGroupID INT
	DECLARE @TestCenterLocationID INT
	DECLARE @ReturnValue int
	DECLARE @maxid int
	DECLARE @LookupTypeID INT
	
	IF NOT EXISTS (SELECT 1 FROM Products WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName)))
	BEGIn
		INSERT INTO Products (ProductGroupName) Values (LTRIM(RTRIM(@ProductGroupName)))
	END
	
	IF NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='ProductType' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@ProductType)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='ProductType'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@ProductType)))
	END
	
	IF LTRIM(RTRIM(@AccessoryGroupName)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='AccessoryType' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@AccessoryGroupName)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='AccessoryType'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@AccessoryGroupName)))
	END
	
	IF LTRIM(RTRIM(@TestCenterLocation)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='TestCenter' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@TestCenterLocation)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='TestCenter'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@TestCenterLocation)))
	END
	
	IF @RequestPurposeID = 0
	BEGIN
		SELECT @RequestPurposeID = LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='RequestPurpose' AND [Values] = @RequestPurpose
	END

	IF @PriorityID = 0
	BEGIN
		SELECT @PriorityID = LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Priority' AND [Values] = @Priority
	END

	IF LTRIM(RTRIM(@Department)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Department' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Department)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Department'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@Department)))
	END

	SELECT @ProductID = ID FROM Products WITH(NOLOCK) WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName))
	SELECT @ProductTypeID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='ProductType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@ProductType))
	SELECT @AccessoryGroupID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='AccessoryType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@AccessoryGroupName))
	SELECT @TestCenterLocationID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='TestCenter' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@TestCenterLocation))
	SELECT @DepartmentID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Department' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@Department))
		
	IF (@ID IS NULL)
	BEGIN
		INSERT INTO Batches(
		QRANumber, 
		Priority, 
		BatchStatus, 
		JobName,
		TestStageName, 
		ProductTypeID,
		AccessoryGroupID,
		TestCenterLocationID,
		RequestPurpose,
		Comment,
		LastUser,
		TestStageCompletionStatus,
		Requestor,
		unitsToBeReturnedToRequestor,
		expectedSampleSize,
		relabJobID,
		reportApprovedDate,
		reportRequiredBy,
		rqID,
		partName,
		assemblyNumber,
		assemblyRevision,
		trsStatus,
		cprNumber,
		hwRevision,
		pmNotes,
		ProductID, IsMQual, MechanicalTools, DepartmentID ) 
		VALUES 
		(@QRANumber, 
		@PriorityID, 
		@BatchStatus, 
		@JobName,
		@TestStageName,
		@ProductTypeID,
		@AccessoryGroupID,
		@TestCenterLocationID,
		@RequestPurposeID,
		@Comment,
		@LastUser,
		@testStageCompletionStatus,
		@Requestor,
		@unitsToBeReturnedToRequestor,
		@expectedSampleSize,
		@relabJobID,
		@reportApprovedDate,
		@reportRequiredBy,
		@rqID,
		@partName,
		@assemblyNumber,
		@assemblyRevision,
		@trsStatus,
		@cprNumber,
		@hwRevision,
		@pmNotes,
		@ProductID, @IsMQual, @MechanicalTools, @DepartmentID)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Batches SET 
		QRANumber = @QRANumber, 
		Priority = @PriorityID, 
		Jobname = @Jobname, 
		TestStagename = @TestStagename, 
		BatchStatus = @BatchStatus, 
		ProductTypeID = @ProductTypeID,
		AccessoryGroupID = @AccessoryGroupID,
		TestCenterLocationID=@TestCenterLocationID,
		RequestPurpose=@RequestPurposeID,
		Comment = @Comment, 
		LastUser = @LastUser,
		Requestor = @Requestor,
		TestStageCompletionStatus = @testStageCompletionStatus,
		unitsToBeReturnedToRequestor=@unitsToBeReturnedToRequestor,
		expectedSampleSize=@expectedSampleSize,
		relabJobID=@relabJobID,
		reportApprovedDate=@reportApprovedDate,
		reportRequiredBy=@reportRequiredBy,
		rqID=@rqID,
		partName=@partName,
		assemblyNumber=@assemblyNumber,
		assemblyRevision=@assemblyRevision,
		trsStatus=@trsStatus,
		cprNumber=@cprNumber,
		hwRevision=@hwRevision,
		pmNotes=@pmNotes ,
		ProductID=@ProductID,
		IsMQual = @IsMQual,
		MechanicalTools = @MechanicalTools, DepartmentID = @DepartmentID
		WHERE (ID = @ID) AND (ConcurrencyID = @ConcurrencyID)

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Batches WITH(NOLOCK) WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
GRANT EXECUTE ON remispBatchesInsertUpdateSingleItem TO Remi
GO