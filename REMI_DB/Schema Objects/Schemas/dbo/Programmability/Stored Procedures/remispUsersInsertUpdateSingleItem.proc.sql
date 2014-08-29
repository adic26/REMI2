ALTER PROCEDURE [dbo].[remispUsersInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispUsersInsertUpdateSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: Users
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int OUTPUT,
	@LDAPLogin nvarchar(255),
	@BadgeNumber int=null,
	@TestCentreID INT = null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@IsActive INT = 1,
	@ByPassProduct INT = 0,
	@DefaultPage NVARCHAR(255)
AS
	DECLARE @ReturnValue int

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO Users (LDAPLogin, BadgeNumber, TestCentreID, LastUser, IsActive, DefaultPage, ByPassProduct)
		VALUES
		(
			@LDAPLogin,
			@BadgeNumber,
			@TestCentreID,
			@LastUser,
			@IsActive,
			@DefaultPage,
			@ByPassProduct
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Users SET
			LDAPLogin = @LDAPLogin,
			BadgeNumber=@BadgeNumber,
			TestCentreID = @TestCentreID,
			lastuser=@LastUser,
			IsActive=@IsActive,
			DefaultPage = @DefaultPage,
			ByPassProduct = @ByPassProduct
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