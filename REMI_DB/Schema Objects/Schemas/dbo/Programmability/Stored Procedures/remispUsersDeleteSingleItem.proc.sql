ALTER PROCEDURE [dbo].[remispUsersDeleteSingleItem]
/*	'===============================================================
	'   NAME:                	remispUsersDeleteSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Deletes an item from table: Users
	'   IN:        ID of item          
	'   OUT: 		Nothing         
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@userIDToDelete nvarchar(255),
	@UserID INT
AS
	update UsersProducts 
	set LastUser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID) 
	FROM UsersProducts
	where UserID = @userIDToDelete

	delete from UsersProducts where UserID = @userIDToDelete

	update	Users set LastUser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID)  where ID = @userIDToDelete
	delete from users where ID = @userIDToDelete
GO
GRANT EXECUTE ON remispUsersDeleteSingleItem TO Remi
GO