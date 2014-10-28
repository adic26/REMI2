ALTER procedure [dbo].[remispUsersSearch] @ProductID INT = 0, @TestCenterID INT = 0, @TrainingID INT = 0, @TrainingLevelID INT = 0, @ByPass INT = 0, @showAllGrid BIT = 0, @UserID INT = 0, @DepartmentID INT = 0
AS
BEGIN
	IF (@showAllGrid = 0)
	BEGIN
		SELECT DISTINCT u.ID, u.LDAPLogin
		FROM Users u
			LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
			LEFT OUTER JOIN UsersProducts up ON up.UserID = u.ID
		WHERE u.IsActive=1 AND (
				(u.TestCentreID=@TestCenterID) 
				OR
				(@TestCenterID = 0)
			  )
			  AND
			  (
				(ut.LookupID=@TrainingID) 
				OR
				(@TrainingID = 0)
			  )
			  AND
			  (
				(ut.LevelLookupID=@TrainingLevelID) 
				OR
				(@TrainingLevelID = 0)
			  )
			  AND
			  (
				(u.ByPassProduct=@ByPass) 
				OR
				(@ByPass = 0)
			  )
			  AND
			  (
				(up.ProductID=@ProductID) 
				OR
				(@ProductID = 0)
			  )
			  AND 
			  (
				(u.DepartmentID=@DepartmentID) 
				OR
				(@DepartmentID = 0)
			  )
		ORDER BY u.LDAPLogin
	END
	ELSE
	BEGIN
		DECLARE @rows VARCHAR(8000)
		DECLARE @query VARCHAR(4000)
		SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + l.[Values]
		FROM Lookups l
			INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
		WHERE lt.Name='Training' And l.IsActive=1
		AND (
				(l.LookupID=@TrainingID) 
				OR
				(@TrainingID = 0)
			  )
		ORDER BY '],[' + l.[Values]
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

		SET @query = '
			SELECT *
			FROM
			(
				SELECT CASE WHEN ut.lookupID IS NOT NULL THEN (CASE WHEN ut.LevelLookupID IS NULL THEN ''*'' ELSE (SELECT SUBSTRING([values], 1, 1) FROM Lookups WHERE LookupID=LevelLookupID) END) ELSE NULL END As Row, u.LDAPLogin, l.[values] As Training
				FROM Users u WITH(NOLOCK)
					LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
					LEFT OUTER JOIN Lookups l on l.lookupid=ut.lookupid
				WHERE u.IsActive = 1 AND (
				(u.TestCentreID=' + CONVERT(VARCHAR, @TestCenterID) + ') 
				OR
				(' + CONVERT(VARCHAR, @TestCenterID) + ' = 0)
			  )
			  AND
			  (
				(ut.LookupID=' + CONVERT(VARCHAR, @TrainingID) + ') 
				OR
				(' + CONVERT(VARCHAR, @TrainingID) + ' = 0)
			  )
			  AND
			  (
				(u.ID=' + CONVERT(VARCHAR, @UserID) + ')
				OR
				(' + CONVERT(VARCHAR, @UserID) + ' = 0)
			  )
			)r
			PIVOT 
			(
				MAX(row) 
				FOR Training 
					IN ('+@rows+')
			) AS pvt'
		EXECUTE (@query)	
	END
END
GO
GRANT EXECUTE ON remispUsersSearch TO REMI
GO