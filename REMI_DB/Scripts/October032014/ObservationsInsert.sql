BEGIN TRAN

DECLARE @ID INT
DECLARE @val NVARCHAR(255)
DECLARE @Level2ID INT
DECLARE @Level2val NVARCHAR(255)
DECLARE @Level2Parent NVARCHAR(255)
DECLARE @LookupID INT
DECLARE @fromTable NVARCHAR(255)
CREATE TABLE #Observations (ID INT IDENTITY(1,1), fromTable NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS, level1 NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS, level2 NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS, level3 NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS, level4 NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS, level5 NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS, level6 NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS)

DELETE FROM dbo.Cosmetic$ WHERE Level1 IS NULL
DELETE FROM dbo.Cracks$ WHERE Level1 IS NULL
DELETE FROM dbo.Delamination$ WHERE Level1 IS NULL
DELETE FROM dbo.Detachment$ WHERE Level1 IS NULL
DELETE FROM dbo.DeviceFunctionality$ WHERE Level1 IS NULL
DELETE FROM dbo.Seperation$ WHERE Level1 IS NULL

INSERT INTO #Observations (fromTable, level1, level2, level3, level4, level5, level6)
SELECT DISTINCT 'Cosmetic', Level1, level2, level3, level4, NULL AS level5, NULL AS level6 FROM dbo.Cosmetic$
UNION
SELECT DISTINCT 'Cracks', level1, level2, level3, level4, NULL AS level5, NULL AS level6 FROM dbo.Cracks$
UNION
SELECT DISTINCT 'Delamination', level1, level2, level3, NULL AS level4, NULL AS level5, NULL AS level6 FROM dbo.Delamination$
UNION
SELECT DISTINCT 'Detachment', level1, level2, level3, NULL AS level4, NULL AS level5, NULL AS level6 FROM dbo.Detachment$
UNION
SELECT DISTINCT 'DeviceFunctionality', level1, level2, level3, level4, level5, level6 FROM dbo.DeviceFunctionality$
UNION
SELECT DISTINCT 'Seperation', level1, level2, level3, NULL AS level4, NULL AS level5, NULL AS level6 FROM dbo.Seperation$

--INSERT TOP LEVEL
SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups

INSERT INTO Lookups (LookupID, [Type], [Values], IsActive, [Description], ParentID)
SELECT ROW_NUMBER() OVER( ORDER BY [Values]) + @LookupID AS LookupID, [Type], [Values], IsActive, [Description], ParentID
FROM (
	SELECT DISTINCT 'Observations' AS [Type], fromtable AS [Values], 1 AS IsActive, NULL AS Description, NULL AS ParentID
	FROM #Observations
	) a

--INSERT LEVEL1
SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups

INSERT INTO Lookups (LookupID, [Type], [Values], IsActive, [Description], ParentID)
SELECT ROW_NUMBER() OVER( ORDER BY [Values]) + @LookupID AS LookupID, [Type], [Values], IsActive, [Description], ParentID
FROM (
	SELECT DISTINCT 'Observations' AS [Type], fromtable, Level1 AS [Values], 1 AS IsActive, NULL AS Description, 
		(SELECT LookupID FROM Lookups WHERE Type='Observations' AND [Values]=fromTable) AS ParentID
	FROM #Observations
	) a

--INSERT LEVEL2
SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups

INSERT INTO Lookups (LookupID, [Type], [Values], IsActive, [Description], ParentID)
SELECT ROW_NUMBER() OVER( ORDER BY [Values]) + @LookupID AS LookupID, [Type], [Values], IsActive, [Description], ParentID
FROM (
	SELECT DISTINCT 'Observations' AS [Type], fromtable, Level1 AS level1, Level2 AS [Values], 1 AS IsActive, NULL AS Description, 
		(SELECT LookupID 
		FROM Lookups 
		WHERE Type='Observations' AND [Values]=level1 AND ParentID IS NOT NULL AND ParentID =
			(SELECT LookupID 
			FROM Lookups 
			WHERE Type='Observations' AND [values]=fromtable AND ParentID IS NULL)
		) AS ParentID
	FROM #Observations
	) a

--INSERT LEVEL3
SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups

INSERT INTO Lookups (LookupID, [Type], [Values], IsActive, [Description], ParentID)
SELECT ROW_NUMBER() OVER( ORDER BY [Values]) + @LookupID AS LookupID, [Type], [Values], IsActive, [Description], ParentID
FROM (
	SELECT DISTINCT 'Observations' AS [Type], fromtable, Level1, Level2, Level3 AS [Values], 1 AS IsActive, NULL AS Description, 
		(
		SELECT LookupID
		FROM Lookups
		WHERE Type='Observations' AND [Values]=level2 AND ParentID IS NOT NULL AND ParentID =
			(SELECT LookupID 
			FROM Lookups 
			WHERE Type='Observations' AND [Values]=level1 AND ParentID IS NOT NULL AND ParentID =
				(SELECT LookupID 
				FROM Lookups 
				WHERE Type='Observations' AND [values]=fromtable AND ParentID IS NULL)
			)) AS ParentID
	FROM #Observations
	WHERE Level3 IS NOT NULL
	) a


--INSERT LEVEL4
SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups

INSERT INTO Lookups (LookupID, [Type], [Values], IsActive, [Description], ParentID)
SELECT ROW_NUMBER() OVER( ORDER BY [Values]) + @LookupID AS LookupID, [Type], [Values], IsActive, [Description], ParentID
FROM (
	SELECT DISTINCT 'Observations' AS [Type], fromtable, Level1, Level2, Level3, level4 AS [Values], 1 AS IsActive, NULL AS Description, 
		(SELECT LookupID
		FROM Lookups
		WHERE Type='Observations' AND [Values]=level3 AND ParentID IS NOT NULL AND ParentID =
			(SELECT LookupID
			FROM Lookups
			WHERE Type='Observations' AND [Values]=level2 AND ParentID IS NOT NULL AND ParentID =
				(SELECT LookupID 
				FROM Lookups 
				WHERE Type='Observations' AND [Values]=level1 AND ParentID IS NOT NULL AND ParentID =
					(SELECT LookupID 
					FROM Lookups 
					WHERE Type='Observations' AND [values]=fromtable AND ParentID IS NULL)
				))) AS ParentID
	FROM #Observations
	WHERE Level3 IS NOT NULL AND level4 IS NOT NULL
	) a


--INSERT LEVEL5
SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups

INSERT INTO Lookups (LookupID, [Type], [Values], IsActive, [Description], ParentID)
SELECT ROW_NUMBER() OVER( ORDER BY [Values]) + @LookupID AS LookupID, [Type], [Values], IsActive, [Description], ParentID
FROM (
	SELECT DISTINCT 'Observations' AS [Type], fromtable, Level1, Level2, Level3, level4, Level5 AS [Values], 1 AS IsActive, NULL AS Description, 
		(SELECT LookupID
		FROM Lookups
		WHERE Type='Observations' AND [Values]=level4 AND ParentID IS NOT NULL AND ParentID =
			(SELECT LookupID
			FROM Lookups
			WHERE Type='Observations' AND [Values]=level3 AND ParentID IS NOT NULL AND ParentID =
				(SELECT LookupID
				FROM Lookups
				WHERE Type='Observations' AND [Values]=level2 AND ParentID IS NOT NULL AND ParentID =
					(SELECT LookupID 
					FROM Lookups 
					WHERE Type='Observations' AND [Values]=level1 AND ParentID IS NOT NULL AND ParentID =
						(SELECT LookupID 
						FROM Lookups 
						WHERE Type='Observations' AND [values]=fromtable AND ParentID IS NULL)
					)))) AS ParentID
	FROM #Observations
	WHERE Level3 IS NOT NULL AND level4 IS NOT NULL AND level5 IS NOT NULL
	) a

--INSERT LEVEL6
SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups

INSERT INTO Lookups (LookupID, [Type], [Values], IsActive, [Description], ParentID)
SELECT ROW_NUMBER() OVER( ORDER BY [Values]) + @LookupID AS LookupID, [Type], [Values], IsActive, [Description], ParentID
FROM (
	SELECT DISTINCT 'Observations' AS [Type], fromtable, Level1, Level2, Level3, level4, Level5, Level6 AS [Values], 1 AS IsActive, NULL AS Description, 
		(SELECT LookupID
		FROM Lookups
		WHERE Type='Observations' AND [Values]=level5 AND ParentID IS NOT NULL AND ParentID =
			(SELECT LookupID
			FROM Lookups
			WHERE Type='Observations' AND [Values]=level4 AND ParentID IS NOT NULL AND ParentID =
				(SELECT LookupID
				FROM Lookups
				WHERE Type='Observations' AND [Values]=level3 AND ParentID IS NOT NULL AND ParentID =
					(SELECT LookupID
					FROM Lookups
					WHERE Type='Observations' AND [Values]=level2 AND ParentID IS NOT NULL AND ParentID =
						(SELECT LookupID 
						FROM Lookups 
						WHERE Type='Observations' AND [Values]=level1 AND ParentID IS NOT NULL AND ParentID =
							(SELECT LookupID 
							FROM Lookups 
							WHERE Type='Observations' AND [values]=fromtable AND ParentID IS NULL)
						))))) AS ParentID
	FROM #Observations
	WHERE Level3 IS NOT NULL AND level4 IS NOT NULL AND level5 IS NOT NULL AND level6 IS NOT NULL
	) a

SELECT * FROM Lookups WHERE [Type]='Observations' 

DROP TABLE #Observations

ROLLBACK TRAN