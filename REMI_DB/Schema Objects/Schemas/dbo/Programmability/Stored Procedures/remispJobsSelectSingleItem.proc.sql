ALTER PROCEDURE [dbo].[remispJobsSelectSingleItem] @ID int = null, @JobName nvarchar(300) = null
AS
BEGIN
	SELECT ID, JobName, WILocation, Comment, LastUser, ConcurrencyID, OperationsTest, TechnicalOperationsTest, MechanicalTest, ProcedureLocation, ISNULL(IsActive, 0) AS IsActive,
		ISNULL(NoBSN, 0) AS NoBSN, ISNULL(ContinueOnFailures, 0) As ContinueOnFailures
	FROM Jobs
	WHERE 
		(
			(@ID > 0 and @JobName is null) 
			and ID = @ID
		) 
		OR 
		(
			(@ID is null and @JobName is not null) 
			and JobName = @JobName
		)
		OR
		(
			@ID IS NULL AND @JobName IS NULL AND ISNULL(IsActive, 0) = 1
		)
END
GO
GRANT EXECUTE ON remispJobsSelectSingleItem TO REMI
GO