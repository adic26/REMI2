ALTER PROCEDURE [dbo].[remispProductSettingsInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispProductSettingsInsertUpdateSingleItem
	'   DATE CREATED:       	4 Nov 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: Jobs
	'							Deletes the item if the value text is null
    '   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ProductID INT,
	@KeyName nvarchar(MAX),
	@ValueText nvarchar(MAX) = null,
	@DefaultValue nvarchar(MAX),
	@LastUser nvarchar(255)	
AS
	DECLARE @ReturnValue int
	declare @ID int
	
	set @ID = (select ID from ProductSettings as ps  where ps.KeyName = @KeyName and productid=@ProductID)

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO ProductSettings
		(
			Productid, 
			KeyName,
			ValueText,
			LastUser,
			DefaultValue
		)
		VALUES
		(
			@ProductID, 
			@KeyName,
			@ValueText,
			@LastUser,
			@DefaultValue
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN	
		if (select defaultvalue from ProductSettings where ID = @ID) != @DefaultValue
		begin
			--update the defaultvalues for any entries
			update ProductSettings set ValueText = @DefaultValue where ValueText = DefaultValue and KeyName = @KeyName;
			update ProductSettings set DefaultValue = @DefaultValue where KeyName = @KeyName;
		end
		
		--and update everything else
		UPDATE ProductSettings SET
			productid = @ProductID, 
			LastUser = @LastUser,
			KeyName = @KeyName,
			ValueText = ISNULL(@ValueText, '')
		WHERE ID = @ID
		SELECT @ReturnValue = @ID
	END
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
GRANT EXECUTE ON remispProductSettingsInsertUpdateSingleItem TO Remi
go