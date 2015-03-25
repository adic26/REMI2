ALTER PROCEDURE [dbo].[remispProductManagersDeleteSingleItem]
/*	'===============================================================
	'   NAME:                	remispProductManagersDeleteSingleItem
	'   DATE CREATED:       	11 Sept 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Deletes an item from table: UsersXProductGroups
	'   IN:        UserID of user, ProductGroupID of productGroup          
	'   OUT: 		Nothing         
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@UserIDToRemove INT,
	@ProductID INT,
	@UserID INT
AS
	update UsersProducts 
	set lastuser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID)
	FROM UsersProducts
		INNER JOIN Products p ON UsersProducts.ProductID=p.ID
	WHERE p.ID = @ProductID and UserID = @UserIDToRemove

	delete UsersProducts
	from UsersProducts
		INNER JOIN Products p ON UsersProducts.ProductID=p.ID
	WHERE p.ID = @ProductID and UserID = @UserIDToRemove
GO
GRANT EXECUTE ON remispProductManagersDeleteSingleItem TO Remi
GO