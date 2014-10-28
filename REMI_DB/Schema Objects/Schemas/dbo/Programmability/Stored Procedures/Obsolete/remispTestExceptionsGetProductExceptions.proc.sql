ALTER procedure [dbo].[remispTestExceptionsGetProductExceptions]
	@ProductID INT = null,
	@recordCount  int  = null output,
	@startrowindex int = -1,
	@maximumrows int = -1
AS
IF (@RecordCount IS NOT NULL)
	BEGIN
		SELECT @RecordCount = COUNT(pvt.ID)
		FROM vw_ExceptionsPivoted as pvt
		where [TestUnitID] IS NULL AND (([ProductID]=@ProductID) OR (@ProductID = 0 AND pvt.ProductID IS NULL))
return
end

--get any exceptions for the product
select ID, BatchUnitNumber, ReasonForRequest, ProductGroupName, JobName, TestStageName, TestName, LastUser, TestStageID, TestUnitID, ProductTypeID, 
	AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID, IsMQual, TestCenter, TestCenterID
from 
(
	select ROW_NUMBER() over (order by p.ProductGroupName desc)as row, pvt.ID, null as batchunitnumber, pvt.[ReasonForRequest], p.ProductGroupName,
	(select jobname from jobs WITH(NOLOCK),TestStages WITH(NOLOCK) where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
	(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, 
	t.TestName,pvt.TestStageID, pvt.TestUnitID,
	(select top 1 LastUser from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
	pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID,
	pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
		LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=pvt.ProductTypeID
		LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.LookupID=pvt.AccessoryGroupID
		LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
		LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.LookupID=pvt.TestCenterID
	WHERE pvt.TestUnitID IS NULL AND
		(
			(pvt.[ProductID]=@ProductID) 
			OR
			(@ProductID = 0 AND pvt.[ProductID] IS NULL)
		)) as exceptionResults
where ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1)
ORDER BY TestName
GO
GRANT EXECUTE ON remispTestExceptionsGetProductExceptions TO Remi
GO