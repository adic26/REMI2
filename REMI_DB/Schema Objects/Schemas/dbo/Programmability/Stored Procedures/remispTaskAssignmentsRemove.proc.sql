ALTER procedure [dbo].[remispTaskAssignmentsRemove] @QRANumber nvarchar(11), @TaskID int
AS
	DECLARE @batchID INT = (SELECT ID FROM Batches WHERE QRANumber=@QRANumber)
	DECLARE @taskAssignmentID INT = (SELECT ID FROM TaskAssignments WHERE BatchID = @batchID AND ISNULL(TaskID, 0) = @TaskID AND Active=1)
	
	PRINT @batchID
	PRINT @taskAssignmentID

	IF (@taskAssignmentID is not null)
	BEGIN
		UPDATE TaskAssignments
		SET Active = 0, assignedon = getutcdate()
		WHERE ID = @taskAssignmentID

		SELECT @taskAssignmentID
	END
GO
GRANT EXECUTE ON [dbo].[remispTaskAssignmentsRemove] TO REMI
GO