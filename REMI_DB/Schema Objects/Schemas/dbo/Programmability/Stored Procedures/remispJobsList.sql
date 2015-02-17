ALTER PROCEDURE [dbo].remispJobsList @UserID INT, @RequestTypeID INT
AS
	BEGIN
		DECLARE @TrueBit BIT
		SET @TrueBit = CONVERT(BIT, 1)
		
		SELECT ja.JobID
		INTO #JobAccess
		FROM UserDetails ud 
			INNER JOIN Lookups l ON l.LookupID=ud.LookupID
			INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID AND lt.Name='Department'
			INNER JOIN JobAccess ja ON ja.LookupID=ud.LookupID
			INNER JOIN Req.RequestTypeAccess rta ON rta.LookupID = ja.LookupID
		WHERE ud.UserID=@UserID AND rta.RequestTypeID=@RequestTypeID
		
		SELECT j.ID, j.JobName, j.IsActive, j.ContinueOnFailures, j.LastUser, j.NoBSN, j.TechnicalOperationsTest, j.ProcedureLocation, j.MechanicalTest,
			j.WILocation, j.OperationsTest, j.Comment
		FROM Jobs j
		WHERE j.IsActive=@TrueBit AND j.ID IN (SELECT JobID FROM #JobAccess)
		ORDER BY j.JobName
		
		DROP TABLE #JobAccess
	END
Go
GRANT EXECUTE ON remispJobsList TO REMI
GO