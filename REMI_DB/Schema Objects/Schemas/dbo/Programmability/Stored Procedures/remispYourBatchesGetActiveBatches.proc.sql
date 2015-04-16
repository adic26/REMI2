ALTER PROCEDURE [dbo].[remispYourBatchesGetActiveBatches] @UserID int, @ByPassProductCheck INT = 0, @Year INT = 0, @OnlyShowQRAWithResults INT = 0
AS	
SELECT b.ID, lp.[Values] AS ProductGroupName,b.QRANumber, (b.QRANumber + ' ' + lp.[Values]) AS Name
	FROM Batches as b WITH(NOLOCK)
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
WHERE ( 
		(@Year = 0 AND BatchStatus NOT IN(5,7))
		OR
		(@Year > 0 AND b.QRANumber LIKE '%-' + RIGHT(CONVERT(NVARCHAR, @Year), 2) + '-%')
	  )
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND lp.LookupID IN (SELECT up.LookupID FROM UserDetails up WITH(NOLOCK) WHERE UserID=@UserID)))
	AND (@OnlyShowQRAWithResults = 0 OR (@OnlyShowQRAWithResults = 1 AND b.ID IN (SELECT tu.BatchID FROM Relab.Results r WITH(NOLOCK) INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID)))
	AND (b.DepartmentID IN (SELECT ud.LookupID 
							FROM UserDetails ud WITH(NOLOCK)
								INNER JOIN Lookups lt WITH(NOLOCK) ON lt.LookupID=ud.LookupID
							WHERE ud.UserID=@UserID))
ORDER BY b.QRANumber DESC
RETURN
GO
GRANT EXECUTE ON remispYourBatchesGetActiveBatches TO Remi
GO