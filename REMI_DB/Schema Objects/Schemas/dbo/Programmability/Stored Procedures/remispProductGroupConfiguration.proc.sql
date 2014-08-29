ALTER PROCEDURE [dbo].[remispProductGroupConfiguration] @pcUID INT AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @rows2 VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	DECLARE @id INT
	CREATE TABLE #results (idkey [int] IDENTITY(1,1),  NodeName varchar(150), ID int, ParentID int, Example varchar(800), Attribute varchar(800), Closing varchar(800))
	CREATE TABLE #results2 (idkey [int] IDENTITY(1,1),  NodeName varchar(150), ID int, ParentID int, Example varchar(800), Attribute varchar(800), Closing varchar(800))

	SELECT @rows=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + l.[Values] 
	FROM ProductConfiguration pc
		INNER JOIN ProductConfigValues val on pc.ID = val.ProductConfigID and ISNULL(isattribute,0)=0
		INNER JOIN Lookups l on val.LookupID=l.LookupID
		INNER JOIN ProductConfigurationUpload pcu ON pcu.ID = pc.UploadID
	WHERE pcu.ID=@pcUID
	ORDER BY '],[' +  l.[Values]
	FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SELECT @rows2=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + l.[Values] 
	FROM ProductConfiguration pc
		INNER JOIN ProductConfigValues val on pc.ID = val.ProductConfigID and ISNULL(isattribute,0)=1
		INNER JOIN Lookups l on val.LookupID=l.LookupID
		INNER JOIN ProductConfigurationUpload pcu ON pcu.ID = pc.UploadID
	where pcu.ID=@pcUID
	ORDER BY '],[' +  l.[Values]
	FOR XML PATH('')), 1, 2, '') + ']','[na]')
		
	SET @query = '
	select NodeName, ProductConfiguration.ID, ParentID, 
	(
		SELECT pvt.* 
		FROM
		(
			SELECT  l.[Values], val.Value
			FROM ProductConfiguration pc
				INNER JOIN ProductConfigValues val on pc.ID=val.ProductConfigID and ISNULL(isattribute,0)=0
				INNER JOIN Lookups l on val.LookupID=l.LookupID
				INNER JOIN ProductConfigurationUpload pcu ON pcu.ID = pc.UploadID
			WHERE pcu.ID=''' + CONVERT(varchar,@pcUID) + ''' and productconfiguration.ID=pc.ID
		)t
		PIVOT (max(Value) FOR t.[Values]
		IN ('+@rows+')) AS pvt
		for xml Path('''')
	) as example,
	(
		select ''<'' + productconfiguration.NodeName + '' '' + cast
		(
			(select CAST
				(
					(SELECT pvt.*
					FROM
						(
							SELECT  l.[Values], val.Value
							FROM ProductConfiguration pc
								INNER JOIN ProductConfigValues val on pc.ID=val.ProductConfigID and ISNULL(isattribute,0)= 1
								INNER JOIN Lookups l on val.LookupID=l.LookupID
								INNER JOIN ProductConfigurationUpload pcu ON pcu.ID = pc.UploadID
							where pcu.ID=''' + CONVERT(varchar,@pcUID) + ''' and productconfiguration.ID=pc.ID
						)t
					PIVOT (max(Value) FOR t.[Values]
					IN ('+@rows2+')) AS pvt
					for xml Path(''Attribute''))
				as xml)
			).query(''for $i in /Attribute/* return concat(local-name($i), "=""", data($i), """")'')
		as nvarchar(max)) + '' />''
	) AS Attribute, ''</'' + productconfiguration.NodeName + ''>'' AS Closing
	from productconfiguration 
		INNER JOIN ProductConfigurationUpload pcu ON pcu.ID = UploadID
	where pcu.ID=''' + CONVERT(varchar,@pcUID) + ''' 
	ORDER BY ViewOrder'

	INSERT INTO #results
		EXECUTE (@query)	

	SELECT @id= MIN(idkey) FROM #results WHERE ParentID IS NOT NULL

	IF EXISTS (SELECT idkey FROM #results WHERE ParentID IS NULL)
		INSERT INTO #results2 SELECT NodeName, ID, ParentID, Example, Attribute, Closing FROM #results WHERE ParentID IS NULL

	WHILE (@id is not null)
	BEGIN
		IF EXISTS (SELECT idkey FROM #results WHERE idkey=@id)
			INSERT INTO #results2 SELECT NodeName, ID, ParentID, Example, Attribute, Closing FROM #results WHERE idkey=@id

		SELECT @id= MIN(idkey) FROM #results WHERE idkey > @id AND ParentID IS NOT NULL
	END

	SELECT idkey, 
		CASE WHEN Attribute IS NOT NULL AND Example IS NULL AND EXISTS (SELECT 1 FROM #results2 r WHERE r.ParentID=#results2.ID) THEN REPLACE(REPLACE(Attribute,' />',''),'<','') 
		WHEN Attribute IS NOT NULL AND Example IS NULL THEN Attribute 
		WHEN Attribute IS NOT NULL AND Example IS NOT NULL THEN NULL 		
		ELSE NodeName END AS NodeName, ID, ParentID, 
		CASE WHEN Closing IS NOT NULL AND Attribute IS NOT NULL THEN REPLACE(Attribute,'/','') + Example + Closing 
		ELSE Example END As Example
	FROM #results2

	DROP TABLE #results
	DROP TABLE #results2
END
GO
GRANT EXECUTE ON remispProductGroupConfiguration TO REMI
GO