ALTER PROCEDURE remispCheckVersion @Application nvarchar(50)
AS
BEGIN
	DECLARE @ID INT
	DECLARE @VID INT
	DECLARE @VersionNum NVARCHAR(150)
	CREATE TABLE #Versions (major INT, minor INT, build INT, revision INT)
	
	SELECT @ID = ID
	From Applications 
	WHERE LOWER(ApplicationName)=LOWER(LTRIM(RTRIM(@Application)))
	
	SELECT @VID= MIN(ID) FROM ApplicationVersions WHERE AppID=@ID
	
	WHILE @VID IS NOT NULL
	BEGIN
		SELECT @VersionNum = VerNum FROM ApplicationVersions WHERE ID=@VID AND AppID = @ID
		
		INSERT INTO #Versions (major, minor, build, revision)
		SELECT *
		FROM  
			(
				SELECT RowID, s as val
					FROM dbo.Split('.',@VersionNum)
			) a
			PIVOT (
					MAX(val) 
					FOR RowID IN ([1], [2],[3],[4])
				  ) as pvt
				  
		SELECT @VID= MIN(ID) FROM ApplicationVersions WHERE AppID=@ID AND ID > @VID
	END
	
	SELECT * FROM #Versions ORDER BY major DESC, minor DESC, build DESC, revision DESC
	
	DROP TABLE #Versions
END
GO
grant execute on remispCheckVersion to remi
GO