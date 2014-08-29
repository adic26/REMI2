ALTER VIEW [dbo].[vw_ExceptionsAuditPivoted]
AS
SELECT pvt.ID, pvt.[41] AS ProductID, pvt.[2] AS ReasonForRequest, pvt.[3] AS TestUnitID, pvt.[4] AS TestStageID, pvt.[5] AS Test, pvt.[6] AS ProductTypeID, pvt.[7] AS AccessoryGroupID,
	pvt.[3516] AS TestCenterID, pvt.[3517] As IsMQual
FROM 
(SELECT ID, Value, TestExceptionsAudit.LookupID as Look
FROM TestExceptionsAudit) te
PIVOT (MAX(Value) FOR Look IN ([41],[2],[3],[4],[5],[6],[7],[3516],[3517])) as pvt 