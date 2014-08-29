ALTER PROCEDURE [dbo].[remispTestExceptionsDeleteProductGroupException]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsDeleteProductGroupException
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	deletes an item from table: TestUnitTestExceptions
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
		@ReasonForRequest int = null,
		@TestName nvarchar(400) = null,
		@TestStageName nvarchar(400) = null,
		@JobName nvarchar(400) = null,
		@ProductID INT=null,
		@LastUser nvarchar(255),
	@TestStageID INT = NULL
AS
	declare @TestUnitID as int 
	
	if (@teststageid is null)
	begin
		if (@ProductID is not null and @teststagename is not null and @jobname is not null and @testUnitID is null)
		begin
			set @TestStageID = (select ts.id from TestStages as ts, Jobs as j where j.JobName = @JobName and ts.JobID = j.ID and ts.TestStageName = @TestStageName)
		end
	
		select @TestStageId AS TestStageID, @TestUnitID AS TestUnitID;
	END

	SELECT DISTINCT pvt.ID
	INTO #temp
	FROM vw_ExceptionsPivoted pvt
		INNER JOIN Tests t ON pvt.Test = t.ID
	where (ReasonForRequest = @ReasonForRequest or (@ReasonForRequest is null and ReasonForRequest is null))
		and testname=@TestName 
		and (teststageid =@TestStageID or (@TestStageId is null and TestStageID is null))
		and ProductID = @ProductID

	PRINT 'SET The User who is deleting'
	UPDATE TestExceptions
	SET LastUser=@LastUser
	WHERE TestExceptions.ID IN (SELECT ID FROM #temp)
	
	PRINT 'Delete Exception'
	delete from TestExceptions WHERE TestExceptions.ID IN (SELECT ID FROM #temp)

	DROP TABLE #temp
GO
GRANT EXECUTE ON remispTestExceptionsDeleteProductGroupException TO Remi
GO