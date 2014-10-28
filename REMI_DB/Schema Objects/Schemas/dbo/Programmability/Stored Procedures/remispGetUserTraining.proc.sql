ALTER PROCEDURE remispGetUserTraining @UserID INT, @ShowTrainedOnly INT
AS
BEGIN
	DECLARE @LookupTypeID INT
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Training'

	SELECT UserTraining.ID, UserID, DateAdded, Lookups.LookupID, Lookups.[Values] AS TrainingOption, 
		CASE WHEN ID IS NOT NULL THEN CONVERT(BIT,1) ELSE CONVERT(BIT, 0) END AS IsTrained,
		ll.[Values] As Level, ISNULL(UserTraining.LevelLookupID,0) AS LevelLookupID,
		ConfirmDate, CASE WHEN ConfirmDate IS NOT NULL THEN 1 ELSE 0 END AS IsConfirmed, ll.[Values] As Level,
		UserAssigned As UserAssigned
	FROM Lookups
		LEFT OUTER JOIN UserTraining ON UserTraining.LookupID=Lookups.LookupID AND UserTraining.UserID=@UserID
		LEFT OUTER JOIN Lookups ll ON ll.LookupID=UserTraining.LevelLookupID 
	WHERE Lookups.LookupTypeID=@LookupTypeID
		AND 
		(
			(@ShowTrainedOnly = 1 AND CASE WHEN ID IS NOT NULL THEN CONVERT(BIT,1) ELSE CONVERT(BIT, 0) END = CONVERT(BIT,1))
			OR
			(@ShowTrainedOnly = 0)
		)
	ORDER BY Lookups.[Values]
END
GO
GRANT EXECUTE ON remispGetUserTraining TO REMI
GO
