ALTER VIEW [dbo].[vw_GetBatchRequestResult]
AS
SELECT b.QRANumber, b.BatchStatus, b.DateCreated, b.ExecutiveSummary, b.ExpectedSampleSize, b.IsMQual, b.UnitsToBeReturnedToRequestor,
	tu.BatchUnitNumber, tu.BSN, tu.IMEI, lp.[values] AS ProductGroupName, PT.[Values] As ProductType, ag.[Values] As AccessoryGroup,
	tc.[Values] As TestCenter, reqpur.[Values] As RequestPurpose, pty.[Values] As Priority, dpmt.[Values] As Department,
	rtn.[Values] As RequestName, rfs.Name, rfd.Value, ts.TestStageName, t.TestName, mn.[Values] As MeasurementName, 
	m.MeasurementValue, m.LowerLimit, m.UpperLimit, m.Archived, m.Comment, m.DegradationVal, m.Description, m.PassFail, m.ReTestNum,
	mut.[Values] As MeasurementUnitType, ri.Name As InformationName, ri.Value As InformationValue, ri.IsArchived As InformationArchived,
	rp.ParameterName, rp.Value As ParameterValue, rx.VerNum AS XMLVerNum, rx.StationName, rx.StartDate, rx.EndDate
FROM Batches b
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Req.Request rq WITH(NOLOCK) ON rq.RequestNumber=b.QRANumber
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	INNER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.RequestID=rq.RequestID
	INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
	INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
	INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
	INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
	INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
	INNER JOIN Relab.ResultsXML rx WITH(NOLOCK) ON rx.ResultID=r.ID
	INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
	INNER JOIN Relab.ResultsInformation ri WITH(NOLOCK) ON ri.XMLID=rx.ID
	LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rp.ResultMeasurementID=m.ID
	LEFT OUTER JOIN Lookups PT WITH(NOLOCK) ON b.ProductTypeID=PT.LookupID  
	LEFT OUTER JOIN Lookups ag WITH(NOLOCK) ON b.AccessoryGroupID=ag.LookupID  
	LEFT OUTER JOIN Lookups tc WITH(NOLOCK) ON b.TestCenterLocationID=tc.LookupID
	LEFT OUTER JOIN Lookups reqpur WITH(NOLOCK) ON b.RequestPurpose=reqpur.LookupID
	LEFT OUTER JOIN Lookups pty WITH(NOLOCK) ON b.Priority=pty.LookupID
	LEFT OUTER JOIN Lookups dpmt WITH(NOLOCK) ON b.DepartmentID=dpmt.LookupID
	LEFT OUTER JOIN Lookups rtn WITH(NOLOCK) ON rt.TypeID=rtn.LookupID
	INNER JOIN Lookups mn WITH(NOLOCK) ON mn.LookupID = m.MeasurementTypeID 
	INNER JOIN Lookups mut WITH(NOLOCK) ON mut.LookupID = m.MeasurementUnitTypeID
GO