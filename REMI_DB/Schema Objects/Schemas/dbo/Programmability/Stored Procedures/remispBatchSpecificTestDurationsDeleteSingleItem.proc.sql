ALTER PROCEDURE [dbo].[remispBatchSpecificTestDurationsDeleteSingleItem]
	@qraNumber nvarchar(11),
	@testStageID int,
	@Comment nvarchar(1000)=null,
	@LastUser nvarchar(255)
AS
BEGIN
	DECLARE @ReturnValue int
	declare @batchid int = (select id from batches where qranumber = @qranumber)
	declare @TestId int = (select t.id from teststages as ts, Tests as t where ts.ID = @testStageID and t.ID = ts.testid)
	
	declare @ID int = (select id from BatchSpecificTestDurations where BatchID = @batchid and testid = @testid)
	IF (@ID IS not NULL) -- New Item

	BEGIN
		update BatchSpecificTestDurations set LastUser = @LastUser , comment = @comment where ID = @id
		delete from BatchSpecificTestDurations where ID = @id
	END
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
END
GO
GRANT EXECUTE ON remispBatchSpecificTestDurationsDeleteSingleItem TO REMI
GO