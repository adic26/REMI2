ALTER VIEW [dbo].[vw_BatchAudit]
AS
SELECT ba.QRANumber, ba.Priority AS PriorityID, ba.BatchStatus, ba.JobName, ba.TestStageName, ba.UserName, ba.InsertTime, ba.Action, ba.RequestPurpose AS RequestPurposeID, 
lp.[Values] AS ProductGroupName, tc.[Values] AS TestCenter, ba.IsMQual, pt.[Values] AS ProductType, at.[Values] AS AccessoryGroup,
rp.[Values] AS RequestPurpose, pr.[Values] AS Priority
FROM dbo.BatchesAudit AS ba 
INNER JOIN dbo.Products AS p ON p.ID = ba.ProductID
INNER JOIN dbo.Lookups lp ON lp.LookupID=p.LookupID
LEFT OUTER JOIN dbo.Lookups AS at ON at.LookupID = ba.AccessoryGroupID 
LEFT OUTER JOIN dbo.Lookups AS pt ON pt.LookupID = ba.ProductTypeID 
LEFT OUTER JOIN dbo.Lookups AS tc ON tc.LookupID = ba.TestCenterLocationID 
LEFT OUTER JOIN dbo.Lookups AS rp ON rp.LookupID = ba.RequestPurpose 
LEFT OUTER JOIN dbo.Lookups AS pr ON pr.LookupID = ba.Priority