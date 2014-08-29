ALTER PROCEDURE [dbo].[remispTaskAssignmentGetListForBatch] @qranumber nvarchar(255)
AS
BEGIN
	SELECT 0 as TaskID, b.QRANumber as TaskName, ta.AssignedTo, ta.AssignedBy, ta.AssignedOn, ta.BatchID, b.ID
	FROM Batches b
		LEFT OUTER JOIN TaskAssignments ta ON ta.BatchID = b.ID AND ta.Active = 1 AND ta.BatchID = b.ID AND ISNULL(TaskID, 0)=0
	WHERE b.QRANumber = @qranumber 
	UNION
	SELECT ts.ID as TaskID, ts.TestStageName as TaskName, ta.AssignedTo, ta.AssignedBy, ta.AssignedOn, ta.BatchID, b.ID
	FROM TestStages ts
		INNER JOIN jobs j ON j.id = ts.JobID
		INNER JOIN Batches b ON b.JobName = j.JobName
		LEFT OUTER JOIN TaskAssignments ta ON ta.TaskID = ts.id AND ta.Active = 1 AND ta.BatchID = b.ID
	WHERE b.QRANumber = @qranumber
	
	SELECT * FROM Batches WHERE QRANumber = @qranumber
END
GO
GRANT EXECUTE ON remispTaskAssignmentGetListForBatch TO REMI
GO