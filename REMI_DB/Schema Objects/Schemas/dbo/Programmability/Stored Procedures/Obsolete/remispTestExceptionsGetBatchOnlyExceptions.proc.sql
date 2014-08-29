ALTER procedure [dbo].[remispTestExceptionsGetBatchOnlyExceptions] @qraNumber nvarchar(11) = null
AS
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,p.ProductGroupName,b.JobName, ts.teststagename
, t.testname, (SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
pvt.TestStageID, pvt.TestUnitID ,
pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID,
pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND l3.LookupID=pvt.TestCenterID
	, Batches as b, teststages ts WITH(NOLOCK), Jobs j WITH(NOLOCK) 
where b.QRANumber = @qranumber and pvt.TestUnitID is null and (ts.id = pvt.teststageid or pvt.TestStageID is null)
	and (ts.JobID = j.ID or j.ID is null) and (b.JobName = j.JobName or j.JobName is null)
	and 
	(
		(pvt.ProductID is null and pvt.ReasonForRequest = b.RequestPurpose)
		or 
		(pvt.ProductID is null and pvt.ReasonForRequest is null)
	)
	AND
	(
		(b.ProductTypeID IS NOT NULL AND b.ProductTypeID = pvt.ProductTypeID )
		OR 
		pvt.ProductTypeID IS NULL
	)
	AND
	(
		(b.AccessoryGroupID IS NOT NULL AND b.AccessoryGroupID = pvt.AccessoryGroupID)
		OR
		pvt.AccessoryGroupID IS NULL
	)
	AND
	(
		(b.TestCenterLocationID IS NOT NULL AND b.TestCenterLocationID = pvt.TestCenterID)
		OR
		pvt.TestCenterID IS NULL
	)
	AND
	(
		(b.IsMQual IS NOT NULL AND b.IsMQual = pvt.IsMQual)
		OR
		pvt.IsMQual IS NULL
	)

union all

--get any for the test units.
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest, p.ProductGroupName,b.JobName, 
(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
pvt.TestStageID, pvt.TestUnitID,pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID,
pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID=pvt.TestUnitID
	INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND l3.LookupID=pvt.TestCenterID
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
order by pvt.TestUnitID desc,TestName
GO
GRANT EXECUTE ON remispTestExceptionsGetBatchOnlyExceptions TO Remi
GO