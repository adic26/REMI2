ALTER PROCEDURE [dbo].remispJobsList @UserID INT, @RequestTypeID INT, @DepartmentID INT
AS
BEGIN
	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)
	
	IF (@UserID = 0 AND @RequestTypeID = 0)
	BEGIN
		SELECT j.ID, j.JobName, j.IsActive, j.ContinueOnFailures, j.LastUser, j.NoBSN, j.TechnicalOperationsTest, j.ProcedureLocation, j.MechanicalTest,
			j.WILocation, j.OperationsTest, j.Comment
		FROM Jobs j
		WHERE j.IsActive=@TrueBit
		ORDER BY j.JobName
	END
	ELSE
	BEGIN
		CREATE TABLE #JobAccess (JobID INT)
		INSERT INTO #JobAccess(JobID)
		SELECT ja.JobID
		FROM UserDetails ud WITH(NOLOCK)
			INNER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=ud.LookupID
			INNER JOIN LookupType lt WITH(NOLOCK) ON lt.LookupTypeID=l.LookupTypeID AND lt.Name='Department'
			INNER JOIN JobAccess ja WITH(NOLOCK) ON ja.LookupID=ud.LookupID
			INNER JOIN Req.RequestTypeAccess rta WITH(NOLOCK) ON rta.LookupID = ja.LookupID
		WHERE (@UserID = 0 OR ud.UserID=@UserID) AND (@RequestTypeID = 0 OR rta.RequestTypeID=@RequestTypeID)
			AND (@DepartmentID = 0 OR rta.LookupID=@DepartmentID)
	
		SELECT j.ID, j.JobName, j.IsActive, j.ContinueOnFailures, j.LastUser, j.NoBSN, j.TechnicalOperationsTest, j.ProcedureLocation, j.MechanicalTest,
			j.WILocation, j.OperationsTest, j.Comment
		FROM Jobs j
		WHERE j.IsActive=@TrueBit AND (j.ID IN (SELECT JobID FROM #JobAccess))
		ORDER BY j.JobName
		
		DROP TABLE #JobAccess
	END
END
Go
GRANT EXECUTE ON remispJobsList TO REMI
GO