/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 8/8/2014 6:38:50 PM

*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO
PRINT N'Altering [dbo].[remispGetProductConfigurationDetails]'
GO
ALTER PROCEDURE [dbo].[remispGetProductConfigurationDetails] @PCID INT
AS
BEGIN	
	SELECT pc.ID, pc.ParentId AS ParentID, pc.ViewOrder, pc.NodeName, pcv.ID AS ProdConfID, l.[Values] As LookupName, 
		l.LookupID, Value As LookupValue, ISNULL(pcv.IsAttribute, 0) AS IsAttribute
	FROM ProductConfiguration pc
		INNER JOIN ProductConfigValues pcv ON pc.ID = pcv.ProductConfigID
		INNER JOIN Lookups l ON l.LookupID = pcv.LookupID
	WHERE pcv.ProductConfigID=@PCID
	ORDER BY pc.ViewOrder	
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductConfigurationUpload]'
GO
ALTER PROCEDURE [dbo].remispProductConfigurationUpload AS
BEGIN
	CREATE TABLE #temp2 (ID INT, ParentID INT NULL, NodeType INT, LocalName NVARCHAR(100), Text NVARCHAR(2000), ID_temp INT IDENTITY(1,1), ID_NEW INT NULL, ParentID_NEW INT NULL)
	CREATE TABLE #temp3 (LookupID INT, Type NVARCHAR(150), LocalName NVARCHAR(150), ID INT IDENTITY(1,1))
	DECLARE @MaxID INT
	DECLARE @MaxLookupID INT
	DECLARE @idoc INT
	DECLARE @ID INT
	DECLARE @xml XML
	DECLARE @LastUser NVARCHAR(255)

	IF ((SELECT COUNT(*) FROM ProductConfigurationUpload WHERE ISNULL(IsProcessed,0)=0 AND ProductID IN (SELECT ID FROM Products))=0)
		RETURN
	
	WHILE ((SELECT COUNT(*) FROM ProductConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)>0)
	BEGIN
		SELECT TOP 1 @ID=pcu.ID, @xml =pcv.PCXML, @LastUser=pcu.LastUser
		FROM ProductConfigurationUpload pcu
			INNER JOIN ProductConfigurationVersion pcv ON pcu.ID=pcv.UploadID AND pcv.VersionNum=1
		WHERE ISNULL(IsProcessed,0)=0 AND ProductID IN (SELECT ID FROM Products)
		
		exec sp_xml_preparedocument @idoc OUTPUT, @xml
		
		SELECT @MaxID = ISNULL(MAX(ID),0)+1 FROM ProductConfiguration
		SELECT @MaxLookupID = ISNULL(MAX(LookupID),0)+1 FROM Lookups

		SELECT * 
		INTO #temp
		FROM OPENXML(@idoc, '/')

		INSERT INTO #temp2 (ID, ParentID, NodeType, LocalName, Text, ParentID_NEW)
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(ISNULL(ParentID,0)) FROM #temp t WHERE t.ParentID=#temp.ID AND t.ParentID IS NOT NULL)>1
		UNION
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(*) FROM #temp t1 WHERE t1.NodeType=1 AND t1.ParentID=#temp.ID AND t1.ParentID IS NOT NULL GROUP BY t1.ParentID )=1
		UNION
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(ISNULL(ParentID,0)) FROM #temp t WHERE t.NodeType IN (1,2) AND t.ParentID=#temp.ID AND t.ParentID IS NOT NULL AND t.NodeType <> 3)=1
		
		UPDATE #temp2
		SET ID_NEW = ID_temp + @MaxID

		UPDATE #temp2
		SET ParentID_NEW = (SELECT t.ID_NEW FROM #temp2 t WHERE #temp2.ParentID=t.ID)
		WHERE #temp2.ParentID IS NOT NULL

		SET IDENTITY_INSERT ProductConfiguration ON

		INSERT INTO ProductConfiguration (ID, ParentId, ViewOrder, NodeName, LastUser, UploadID)
		SELECT ID_NEW, CASE WHEN ParentID_NEW = 0 THEN NULL ELSE ParentID_NEW END, ROW_NUMBER() OVER (ORDER BY id) AS ViewOrder, LocalName, @LastUser, @ID
		FROM #temp2
		ORDER BY ID, parentid

		SET IDENTITY_INSERT ProductConfiguration OFF
			
		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, 'Configuration' AS Type, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=2 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE Type='Configuration')
			
		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, 'Configuration' AS Type, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=1 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE Type='Configuration')
			AND ID IN (SELECT ParentID FROM #temp WHERE NodeType=3)
		
		UPDATE #temp3 SET LookupID=ID+@MaxLookupID

		insert into Lookups (LookupID, Type, [Values])
		select LookupID, Type, localname as [Values] from #temp3
			
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		SELECT ISNULL((SELECT t2.Text FROM #temp t2 WHERE t2.NodeType=3 AND t2.ParentID=#temp.ID),'') AS Value, 
			CASE WHEN #temp.NodeType=2 THEN (SELECT LookupID FROM Lookups WHERE Type='Configuration' AND [values]=#temp.LocalName) ELSE NULL END As LookupID, 
			(SELECT ID_NEW FROM #temp2 WHERE #temp.ParentID=#temp2.ID) AS ProductConfigID, @LastUser As LastUser, 1 AS IsAttribute
		FROM #temp
		WHERE #temp.NodeType=2 		

		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON Type='Configuration' AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.parentid) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ParentID=t1.ID) AS ProductConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=3 AND ParentID NOT IN (Select ID FROM #temp WHERE #temp.NodeType=2)
			
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON Type='Configuration' AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.id) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ID=t1.ID) AS ProductConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=1 AND ID NOT IN (Select ParentID FROM #temp t WHERE t.NodeType =3)
			AND ID NOT IN (Select ID FROM #temp2)	
		
		UPDATE ProductConfigurationUpload SET IsProcessed=1 WHERE ID=@ID
		
		DELETE FROM #temp2
		DELETE FROM #temp3
		DROP TABLE #temp
	END
		
	DROP TABLE #temp2
	DROP TABLE #temp3	
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispSaveProductConfigurationDetails]'
GO
ALTER PROCEDURE [dbo].[remispSaveProductConfigurationDetails] @PCID INT, @configID INT, @lookupID INT, @lookupValue NVARCHAR(2000), @LastUser NVARCHAR(255), @IsAttribute BIT = 0, @LookupAlt NVARCHAR(255)
AS
BEGIN
	IF (@lookupID = 0 AND LEN(LTRIM(RTRIM(@LookupAlt))) > 0)
	BEGIN
		SELECT @lookupID = LookupID FROM Lookups WHERE [values]=@LookupAlt AND Type='Configuration'
		
		IF (@lookupID IS NULL OR @lookupID = 0)
		BEGIN
			SELECT @lookupID = MAX(LookupID)+1 FROM Lookups
			
			INSERT INTO Lookups (LookupID, Type,[Values], IsActive) VALUES (@lookupID, 'Configuration', LTRIM(RTRIM(@LookupAlt)), 1)
		END
	END

	If ((@configID IS NULL OR @configID = 0 OR NOT EXISTS (SELECT 1 FROM ProductConfigValues WHERE ID=@configID)) AND @lookupValue IS NOT NULL AND LTRIM(RTRIM(@lookupValue)) <> '' AND @LookupID IS NOT NULL AND @LookupID > 0 AND EXISTS(SELECT 1 FROM ProductConfiguration WHERE ID=@PCID))
	BEGIN
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		VALUES (@lookupValue, @LookupID, @PCID, @LastUser, ISNULL(@IsAttribute,0))
	END
	ELSE IF (@configID > 0)
	BEGIN
		UPDATE ProductConfigValues
		SET Value=@lookupValue, LookupID=@LookupID, LastUser=@LastUser, ProductConfigID=@PCID, IsAttribute=ISNULL(@IsAttribute,0)
		WHERE ID=@configID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispDeleteProductConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispDeleteProductConfiguration] @PCUID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	UPDATE ProductConfigValues 
	SET LastUser=@LastUser
	WHERE ProductConfigID IN (SELECT pc.ID FROM ProductConfiguration pc WHERE pc.UploadID=@PCUID)
	
	UPDATE pc 
	SET LastUser=@LastUser
	FROM ProductConfiguration pc
	WHERE pc.UploadID=@PCUID
	
	DELETE FROM ProductConfigValues WHERE ProductConfigID IN (SELECT ID FROM ProductConfiguration WHERE UploadID=@PCUID)
	DELETE ProductConfiguration FROM ProductConfiguration WHERE UploadID=@PCUID
	DELETE FROM ProductConfigurationVersion WHERE UploadID=@PCUID
	DELETE FROM ProductConfigurationUpload WHERE ID=@PCUID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispDeleteProductConfigurationHeader]'
GO
ALTER PROCEDURE [dbo].[remispDeleteProductConfigurationHeader] @PCID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	IF (EXISTS (SELECT 1 FROM ProductConfiguration WHERE ID=@PCID) AND NOT EXISTS (SELECT 1 FROM ProductConfigValues WHERE ProductConfigID=@PCID))
	BEGIN
		DELETE FROM ProductConfiguration WHERE ID=@PCID
	END
	
	IF NOT EXISTS (SELECT 1 FROM ProductConfiguration WHERE ID=@PCID)
	BEGIN
		DELETE FROM ProductConfigurationUpload WHERE ID=@PCID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[CompareXml]'
GO
CREATE FUNCTION [dbo].[CompareXml]
(
    @xml1 XML,
    @xml2 XML
)
RETURNS INT
AS 
BEGIN
    DECLARE @ret INT
    SELECT @ret = 0


    -- -------------------------------------------------------------
    -- If one of the arguments is NULL then we assume that they are
    -- not equal. 
    -- -------------------------------------------------------------
    IF @xml1 IS NULL OR @xml2 IS NULL 
    BEGIN
        RETURN 1
    END

    -- -------------------------------------------------------------
    -- Match the name of the elements 
    -- -------------------------------------------------------------
    IF  (SELECT @xml1.value('(local-name((/*)[1]))','VARCHAR(MAX)')) 
        <> 
        (SELECT @xml2.value('(local-name((/*)[1]))','VARCHAR(MAX)'))
    BEGIN
        RETURN 1
    END

     ---------------------------------------------------------------
     --Match the value of the elements
     ---------------------------------------------------------------
    IF((@xml1.query('count(/*)').value('.','INT') = 1) AND (@xml2.query('count(/*)').value('.','INT') = 1))
    BEGIN
    DECLARE @elValue1 VARCHAR(MAX), @elValue2 VARCHAR(MAX)

    SELECT
        @elValue1 = @xml1.value('((/*)[1])','VARCHAR(MAX)'),
        @elValue2 = @xml2.value('((/*)[1])','VARCHAR(MAX)')

    IF  @elValue1 <> @elValue2
    BEGIN
        RETURN 1
    END
    END

    -- -------------------------------------------------------------
    -- Match the number of attributes 
    -- -------------------------------------------------------------
    DECLARE @attCnt1 INT, @attCnt2 INT
    SELECT
        @attCnt1 = @xml1.query('count(/*/@*)').value('.','INT'),
        @attCnt2 = @xml2.query('count(/*/@*)').value('.','INT')

    IF  @attCnt1 <> @attCnt2 BEGIN
        RETURN 1
    END


    -- -------------------------------------------------------------
    -- Match the attributes of attributes 
    -- Here we need to run a loop over each attribute in the 
    -- first XML element and see if the same attribut exists
    -- in the second element. If the attribute exists, we
    -- need to check if the value is the same.
    -- -------------------------------------------------------------
    DECLARE @cnt INT, @cnt2 INT
    DECLARE @attName VARCHAR(MAX)
    DECLARE @attValue VARCHAR(MAX)

    SELECT @cnt = 1

    WHILE @cnt <= @attCnt1 
    BEGIN
        SELECT @attName = NULL, @attValue = NULL
        SELECT
            @attName = @xml1.value(
                'local-name((/*/@*[sql:variable("@cnt")])[1])', 
                'varchar(MAX)'),
            @attValue = @xml1.value(
                '(/*/@*[sql:variable("@cnt")])[1]', 
                'varchar(MAX)')

        -- check if the attribute exists in the other XML document
        IF @xml2.exist(
                '(/*/@*[local-name()=sql:variable("@attName")])[1]'
            ) = 0
        BEGIN
            RETURN 1
        END

        IF  @xml2.value(
                '(/*/@*[local-name()=sql:variable("@attName")])[1]', 
                'varchar(MAX)')
            <>
            @attValue
        BEGIN
            RETURN 1
        END

        SELECT @cnt = @cnt + 1
    END

    -- -------------------------------------------------------------
    -- Match the number of child elements 
    -- -------------------------------------------------------------
    DECLARE @elCnt1 INT, @elCnt2 INT
    SELECT
        @elCnt1 = @xml1.query('count(/*/*)').value('.','INT'),
        @elCnt2 = @xml2.query('count(/*/*)').value('.','INT')


    IF  @elCnt1 <> @elCnt2
    BEGIN
        RETURN 1
    END


    -- -------------------------------------------------------------
    -- Start recursion for each child element
    -- -------------------------------------------------------------
    SELECT @cnt = 1
    SELECT @cnt2 = 1
    DECLARE @x1 XML, @x2 XML
    DECLARE @noMatch INT

    WHILE @cnt <= @elCnt1 
    BEGIN

        SELECT @x1 = @xml1.query('/*/*[sql:variable("@cnt")]')
    --RETURN CONVERT(VARCHAR(MAX),@x1)
    WHILE @cnt2 <= @elCnt2
    BEGIN
        SELECT @x2 = @xml2.query('/*/*[sql:variable("@cnt2")]')
        SELECT @noMatch = dbo.CompareXml( @x1, @x2 )
        IF @noMatch = 0 BREAK
        SELECT @cnt2 = @cnt2 + 1
    END

    SELECT @cnt2 = 1

        IF @noMatch = 1
        BEGIN
            RETURN 1
        END

        SELECT @cnt = @cnt + 1
    END

    RETURN @ret
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispProductConfigurationSaveXMLVersion]'
GO
CREATE PROCEDURE [dbo].remispProductConfigurationSaveXMLVersion @XML AS NTEXT, @LastUser As NVARCHAR(255), @PCUID INT
AS
BEGIN
	DECLARE @VersionNum INT
	DECLARE @DoInsert INT
	DECLARE @XMLPrev XML
	SELECT @VersionNum = ISNULL(MAX(VersionNum), 0) + 1 FROM ProductConfigurationVersion WHERE UploadID=@PCUID
	
	IF (@VersionNum > 1)
		BEGIN
			SELECT @XMLPrev = PCXML FROM ProductConfigurationVersion WHERE UploadID=@PCUID AND VersionNum = @VersionNum-1
		END
	ELSE
		BEGIN
			SET @XMLPrev = NULL
		END
	
	IF ((SELECT dbo.CompareXml(CONVERT(XML, @XML), @XMLPrev)) = 1)
		BEGIN
			INSERT INTO ProductConfigurationVersion (UploadID, PCXML, LastUser, VersionNum)
			VALUES (@PCUID, CONVERT(XML, @XML), @LastUser, @VersionNum)
		END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetProductConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispGetProductConfiguration] @PCUID INT
AS
BEGIN
	SELECT pc.ID, pcParent.NodeName As ParentName, pc.ParentId AS ParentID, pc.ViewOrder, pc.NodeName,
		ISNULL((
			(SELECT ISNULL(ProductConfiguration.NodeName, '')
			FROM ProductConfiguration
				LEFT OUTER JOIN ProductConfiguration pc2 ON ProductConfiguration.ID = pc2.ParentId
			WHERE pc2.ID = pc.ParentID)
			+ '/' + 
			ISNULL(pcParent.NodeName, '')
		), CASE WHEN pc.ParentId IS NOT NULL THEN pcParent.NodeName ELSE NULL END) As ParentScheme
	FROM ProductConfiguration pc
		LEFT OUTER JOIN ProductConfiguration pcParent ON pc.ParentId=pcParent.ID
		INNER JOIN productConfigurationUpload pcu ON pcu.ID=pc.UploadID
	WHERE pcu.ID=@PCUID
	ORDER BY pc.ViewOrder
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispSaveProductConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispSaveProductConfiguration] @PCID INT, @parentID INT, @ViewOrder INT, @NodeName NVARCHAR(200), @LastUser NVARCHAR(255), @UploadID INT
AS
BEGIN
	If ((@PCID IS NULL OR @PCID = 0 OR NOT EXISTS (SELECT 1 FROM ProductConfiguration WHERE ID=@PCID)) AND @NodeName IS NOT NULL AND LTRIM(RTRIM(@NodeName)) <> '')
	BEGIN
		INSERT INTO ProductConfiguration (ParentId, ViewOrder, NodeName, LastUser, UploadID)
		VALUES (CASE WHEN @parentID = 0 THEN NULL ELSE @parentID END, @ViewOrder, @NodeName, @LastUser, @UploadID)
		
		SET @PCID = SCOPE_IDENTITY()
	END
	ELSE IF (@PCID > 0)
	BEGIN
		UPDATE ProductConfiguration
		SET ParentId=CASE WHEN @parentID = 0 THEN NULL ELSE @parentID END, ViewOrder=@ViewOrder, NodeName=@NodeName, LastUser=@LastUser
		WHERE ID=@PCID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductGroupConfiguration]'
GO
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetSimilarTestConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispGetSimilarTestConfiguration] @productID INT, @TestID INT
AS
BEGIN
	SELECT pc.ProductID AS ID, p.ProductGroupName
	FROM ProductConfigurationUpload pc
		INNER JOIN Products p on pc.ProductID = p.ID
	WHERE pc.TestID=@TestID AND pc.ProductID <> @productID
	GROUP BY pc.ProductID, p.ProductGroupName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remifnTestCanDelete]'
GO
ALTER FUNCTION dbo.remifnTestCanDelete (@TestID INT)
RETURNS BIT
AS
BEGIN
	DECLARE @Exists BIT
	
	SELECT @Exists = (SELECT DISTINCT 0
		FROM ProductConfigurationUpload
		WHERE TestID=@TestID
		UNION
		SELECT DISTINCT 0
		FROM BatchSpecificTestDurations
		WHERE TestID=@TestID
		UNION
		SELECT DISTINCT 0
		FROM Relab.Results
		WHERE TestID=@TestID
		UNION
		SELECT DISTINCT 0
		FROM TestRecords
		WHERE TestID=@TestID)
	
	RETURN ISNULL(@Exists, 1)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductConfigurationProcess]'
GO
ALTER PROCEDURE [dbo].remispProductConfigurationProcess @ProductID INT, @TestID INT, @XML AS NTEXT, @LastUser As NVARCHAR(255), @PCName NVARCHAR(200) = NULL
AS
BEGIN
	IF (@PCName IS NULL OR LTRIM(RTRIM(@PCName)) = '') --Get The Root Name Of the XML
	BEGIN
		DECLARE @xmlTemp XML = CONVERT(XML, @XML)
		SELECT @PCName= LTRIM(RTRIM(x.c.value('local-name(/*[1])','nvarchar(max)')))
		FROM @xmlTemp.nodes('/*') x ( c )
		
		IF (@PCName = '')
		BEGIN
			SET @PCName = 'ProductConfiguration'
		END
	END

	IF EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND ProductID=@ProductID AND PCName=@PCName)
	BEGIN
		DECLARE @increment INT
		DECLARE @PCNameTemp NVARCHAR(200)
		SET @PCNameTemp = @PCName
		SET @increment = 1
		
		WHILE EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND ProductID=@ProductID AND PCName=@PCNameTemp)
		BEGIN
			SET @PCNameTemp = @PCName + CONVERT(NVARCHAR, @increment)
			SET @increment = @increment + 1
			print @PCNameTemp
		END
		
		SET @PCName = @PCNameTemp
	END
	
	IF NOT EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND ProductID=@ProductID AND PCName=@PCName)
	BEGIN
		INSERT INTO ProductConfigurationUpload (IsProcessed, ProductID, TestID, LastUser, PCName) 
		Values (CONVERT(BIT, 0), @ProductID, @TestID, @LastUser, @PCName)
		
		DECLARE @UploadID INT
		SET @UploadID =  @@IDENTITY

		EXEC remispProductConfigurationSaveXMLVersion @XML, @LastUser, @UploadID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispProductConfigurationSaveXMLVersion]'
GO
GRANT EXECUTE ON  [dbo].[remispProductConfigurationSaveXMLVersion] TO [remi]
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO