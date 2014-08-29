ALTER PROCEDURE [dbo].[remispYourBatchesGetActiveBatches] @UserID int, @ByPassProductCheck INT = 0, @Year INT = 0, @OnlyShowQRAWithResults INT = 0
AS	
SELECT b.ID, p.ProductGroupName,b.QRANumber, (b.QRANumber + ' ' + p.ProductGroupName) AS Name
	FROM Batches as b WITH(NOLOCK)
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
WHERE ( 
		(@Year = 0 AND BatchStatus NOT IN(5,7))
		OR
		(@Year > 0 AND b.QRANumber LIKE 'QRA-' + RIGHT(CONVERT(NVARCHAR, @Year), 2) + '%')
	  )
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	AND (@OnlyShowQRAWithResults = 0 OR (@OnlyShowQRAWithResults = 1 AND b.ID IN (SELECT tu.BatchID FROM Relab.Results r INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID)))
ORDER BY b.QRANumber DESC
RETURN
GO
GRANT EXECUTE ON remispYourBatchesGetActiveBatches TO Remi
GO