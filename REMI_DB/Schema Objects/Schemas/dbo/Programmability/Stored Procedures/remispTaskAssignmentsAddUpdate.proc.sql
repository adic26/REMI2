ALTER procedure remispTaskAssignmentsAddUpdate
	@QRANumber nvarchar(11),
	@TaskID INT,
	@AssignedBy nvarchar(255),
	@assignedTo nvarchar(255)
AS
	DECLARE @batchID INT = (SELECT ID FROM Batches WHERE QRANumber=@QRANumber)
	DECLARE @taskAssignmentID INT = (SELECT ID FROM taskassignments WHERE BatchID = @batchID AND ISNULL(TaskID,0) = @TaskID AND Active=1)

	IF (@taskAssignmentID is null)
	BEGIN
		INSERT INTO TaskAssignments (Active, AssignedBy, AssignedTo, BatchID, TaskID, AssignedOn)
		VALUES (1, @AssignedBy, @assignedTo, @batchID, CASE WHEN @TaskID = 0 THEN NULL ELSE @TaskID END, getutcdate())

		SELECT @taskAssignmentID = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE TaskAssignments
		SET Active = 1, AssignedBy = @AssignedBy, AssignedTo = @assignedTo, assignedon = getutcdate()
		WHERE ID = @taskAssignmentID

		SELECT @taskAssignmentID
	END
GO
GRANT EXECUTE ON remispTaskAssignmentsAddUpdate TO REMI
GO