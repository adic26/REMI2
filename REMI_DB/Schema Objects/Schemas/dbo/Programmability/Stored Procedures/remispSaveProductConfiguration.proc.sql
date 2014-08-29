ALTER PROCEDURE remispSaveProductConfiguration @PCID INT, @parentID INT, @ViewOrder INT, @NodeName NVARCHAR(200), @LastUser NVARCHAR(255), @UploadID INT
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
GRANT EXECUTE ON remispSaveProductConfiguration TO REMI
GO