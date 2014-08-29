ALTER PROCEDURE [dbo].[remispProductManagersAssignUser]
/*	'===============================================================
	'   NAME:                	remispProductManagersAssignUser
	'   DATE CREATED:       	11 Sept 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: product managers
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ProductID INT,
	@Username nvarchar(255),
	@LastUser nvarchar(255)	
AS
	DECLARE @ReturnValue int
	Declare @ID int
	Declare @UserID INT
	SELECT @UserID = ID FROM Users WHERE LDAPLogin=@Username

	SET @ID = (Select ID from UsersProducts where productID = @ProductID and UserID = @UserID)

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO UsersProducts (ProductID, UserID, Lastuser)
		VALUES (@ProductID, @UserID, @LastUser)

		SELECT @ReturnValue = SCOPE_IDENTITY()
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
GRANT EXECUTE ON remispProductManagersAssignUser TO Remi
GO