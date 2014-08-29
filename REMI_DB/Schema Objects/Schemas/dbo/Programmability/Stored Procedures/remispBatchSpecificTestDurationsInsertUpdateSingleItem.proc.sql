ALTER PROCEDURE [dbo].[remispBatchSpecificTestDurationsInsertUpdateSingleItem]
@qraNumber nvarchar(11), 
@Duration real, 
@testStageID int,
@Comment nvarchar(1000)=null,	
@LastUser nvarchar(255)
AS
	DECLARE @ReturnValue int
	declare @batchid int = (select id from batches WITH(NOLOCK) where qranumber = @qranumber)
	declare @TestId int = (select t.id from teststages as ts WITH(NOLOCK), Tests as t WITH(NOLOCK) where ts.ID = @testStageID and t.ID = ts.testid)
	
	declare @ID int = (select id from BatchSpecificTestDurations WITH(NOLOCK) where BatchID = @batchid and testid = @testid)
	IF (@ID IS NULL) -- New Item

	BEGIN
		INSERT INTO BatchSpecificTestDurations (TestID, Duration, BatchID, Comment, lastUser)
		VALUES (@TestID, @Duration, @BatchID, @Comment, @lastUser)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE BatchSpecificTestDurations 
		SET testid = @testid, Duration = @Duration, batchid = @batchid, Comment = @Comment, lastUser = @LastUser
		WHERE ID = @ID
		SELECT @ReturnValue = @ID
	END
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
GRANT EXECUTE ON remispBatchSpecificTestDurationsInsertUpdateSingleItem TO REMI
GO