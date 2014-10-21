ALTER PROCEDURE [dbo].[remispUsersInsertUpdateSingleItem]
	@ID int OUTPUT,
	@LDAPLogin nvarchar(255),
	@BadgeNumber int=null,
	@TestCentreID INT = null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@IsActive INT = 1,
	@ByPassProduct INT = 0,
	@DefaultPage NVARCHAR(255),
	@DepartmentID INT = 0
AS
	DECLARE @ReturnValue int

	IF (@ID IS NULL AND NOT EXISTS (SELECT 1 FROM Users WHERE LDAPLogin=@LDAPLogin)) -- New Item
	BEGIN
		INSERT INTO Users (LDAPLogin, BadgeNumber, TestCentreID, LastUser, IsActive, DefaultPage, ByPassProduct, DepartmentID)
		VALUES (@LDAPLogin, @BadgeNumber, @TestCentreID, @LastUser, @IsActive, @DefaultPage, @ByPassProduct, @DepartmentID)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE IF(@ConcurrencyID IS NOT NULL) -- Exisiting Item
	BEGIN
		UPDATE Users SET
			LDAPLogin = @LDAPLogin,
			BadgeNumber=@BadgeNumber,
			TestCentreID = @TestCentreID,
			lastuser=@LastUser,
			IsActive=@IsActive,
			DefaultPage = @DefaultPage,
			ByPassProduct = @ByPassProduct,
			DepartmentID = @DepartmentID
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Users WHERE ID = @ReturnValue)
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