begin tran
go
EXEC sp_rename 'dbo.Products.TSDContact', '_TSDContact', 'COLUMN'
GO
ALTER PROCEDURE [dbo].[remispSaveProduct] @ProductID int , @isActive int, @ProductGroupName NVARCHAR(150), @QAP NVARCHAR(255), @Success AS BIT = NULL OUTPUT
AS
BEGIN
	IF (@ProductID = 0)--ensure we don't have it
	BEGIN
		SELECT @ProductID = ID
		FROM Products p
			INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
		WHERE LTRIM(RTRIM(lp.[values]))=LTRIM(RTRIM(@ProductGroupName))
	END

	IF (@ProductID = 0)--if we still dont have it insert it
	BEGIN
		DECLARE @LookupTypeID INT
		DECLARE @LookupID INT
		SELECT @LookupID = MAX(LookupID)+1 FROM Lookups
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Products'		
				
		INSERT INTO Lookups ([Values], LookupID, IsActive) VALUES (LTRIM(RTRIM(@ProductGroupName)), @LookupID, 1)
		INSERT INTO Products (LookupID, QAPLocation) 
		VALUES (@LookupID, @QAP)

		SET @Success = 1
	END
	ELSE
	BEGIN
		UPDATE Products
		SET QAPLocation = @QAP
		WHERE ID=@ProductID

		SET @Success = 1
	END
END
GRANT EXECUTE ON remispSaveProduct TO REMI
GO
ALTER TABLE dbo.UserDetails ADD IsTSDContact BIT DEFAULT(0) NULL
GO
update UserDetails set IsTSDContact=0

UPDATE ud
SET ud.IsTSDContact=1
FROM UserDetails ud
inner join Users u on ud.UserID=u.ID
inner join Products p on ud.LookupID=p.LookupID AND p._TSDContact=u.LDAPLogin
WHERE ISNULL(_TSDContact,'') <> '' and p.LookupID in (select LookupID from UserDetails where UserID=u.id)

INSERT INTO UserDetails (LookupID,LastUser,IsTSDContact,UserID)
select p.LookupID, u.LDAPLogin, 1, u.ID
from Products p
inner join Users u on p._TSDContact=u.LDAPLogin
where ISNULL(_TSDContact,'') <> ''
and LookupID not in (select LookupID from UserDetails where UserID=u.id)
GO
ALTER PROCEDURE dbo.remispGetContacts @ProductID INT
AS
BEGIN
	SELECT ISNULL(us.LDAPLogin, '') AS TSDContact
	INTO #tempTSD
	FROM UserDetails ud WITH(NOLOCK)
		INNER JOIN Products p WITH(NOLOCK) ON p.LookupID=ud.LookupID
		INNER JOIN Users us WITH(NOLOCK) ON us.ID=ud.UserID
	WHERE ud.IsTSDContact=1 AND p.ID=@ProductID

	SELECT ISNULL(us.LDAPLogin, '') AS ProductManager
	INTO #temp
	FROM UserDetails ud WITH(NOLOCK)
		INNER JOIN Products p WITH(NOLOCK) ON p.LookupID=ud.LookupID
		INNER JOIN Users us WITH(NOLOCK) ON us.ID=ud.UserID
	WHERE ud.IsProductManager=1 AND p.ID=@ProductID
	
	SELECT pm.*, tsd.*
	FROM
	(
		SELECT ProductManager
		FROM #temp
	) pm,
	(
		SELECT TSDContact
		FROM #tempTSD
	) tsd
	
	DROP TABLE #temp
	DROP TABLE #tempTSD
END
GO
GRANT EXECUTE ON [dbo].remispGetContacts TO REMI
GO
ALTER PROCEDURE remispGetUserDetails @UserID INT
AS
BEGIN
	SELECT lt.Name, l.[Values], l.LookupID, ISNULL(ud.IsDefault, 0) AS IsDefault, ud.IsProductManager, ud.IsTSDContact
	FROM UserDetails ud
		INNER JOIN Lookups l ON l.LookupID=ud.LookupID
		INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
	WHERE ud.UserID=@UserID
	ORDER BY lt.Name, l.[Values]
END
GO
GRANT EXECUTE ON remispGetUserDetails TO REMI
GO
DROP TABLE dbo._UsersProducts
DROP TABLE dbo._UsersProductsAudit
GO
ALTER TABLE dbo.Products DROP COLUMN _ProductGroupName
ALTER TABLE dbo.Products DROP COLUMN _IsActive
GO
rollback tran