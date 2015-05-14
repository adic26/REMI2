ALTER PROCEDURE [dbo].[remispUsersInsertUpdateSingleItem]
	@ID int OUTPUT,
	@LDAPLogin nvarchar(255),
	@BadgeNumber int=null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@IsActive INT = 1,
	@ByPassProduct INT = 0,
	@DefaultPage NVARCHAR(255)
AS
	DECLARE @ReturnValue int

	IF (@ID IS NULL AND NOT EXISTS (SELECT 1 FROM Users WITH(NOLOCK) WHERE LDAPLogin=@LDAPLogin)) -- New Item
	BEGIN
		INSERT INTO Users (LDAPLogin, BadgeNumber, LastUser, IsActive, DefaultPage, ByPassProduct)
		VALUES (LTRIM(RTRIM(@LDAPLogin)), @BadgeNumber, @LastUser, @IsActive, @DefaultPage, @ByPassProduct)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE IF(@ConcurrencyID IS NOT NULL) -- Exisiting Item
	BEGIN
		UPDATE Users SET
			LDAPLogin = LTRIM(RTRIM(@LDAPLogin)),
			BadgeNumber=@BadgeNumber,
			lastuser=@LastUser,
			IsActive=@IsActive,
			DefaultPage = @DefaultPage,
			ByPassProduct = @ByPassProduct
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Users WITH(NOLOCK) WHERE ID = @ReturnValue)
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
GRANT EXECUTE ON remispUsersInsertUpdateSingleItem TO Remi
GO