BEGIN TRAN

DECLARE select_cursor CURSOR FOR select rm.ID, l.[Values]
from Relab.ResultsMeasurements rm
inner join Relab.Results r on rm.ResultID=r.ID
inner join TestUnits tu on tu.ID=r.TestUnitID
inner join Batches b on b.ID=tu.BatchID
inner join Lookups l on l.LookupID=rm.MeasurementTypeID
where MeasurementTypeID in (select LookupID
from Lookups
where LookupTypeID=7 and [Values] like '%\%')
OPEN select_cursor

DECLARE @ID INT
DECLARE @Value NVARCHAR(150)

FETCH NEXT FROM select_cursor INTO @ID,@Value

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT @Value
	INSERT INTO Relab.ResultsParameters (ResultMeasurementID,ParameterName,Value)
	select @ID as ResultMeasurementID, CASE WHEN RowID = 1 THEN 'Top Observation' ELSE 'Sub Observation ' + CONVERT(VARCHAR, RowID-1) END as ParameterName , s as Value
	from dbo.Split('\',@Value)


	FETCH NEXT FROM select_cursor INTO @ID,@Value
END

CLOSE select_cursor
DEALLOCATE select_cursor

UPDATE rm
SET rm.MeasurementTypeID=6696
from Relab.ResultsMeasurements rm
inner join Relab.Results r on rm.ResultID=r.ID
inner join TestUnits tu on tu.ID=r.TestUnitID
inner join Batches b on b.ID=tu.BatchID
inner join Lookups l on l.LookupID=rm.MeasurementTypeID
where MeasurementTypeID in (select LookupID
from Lookups
where LookupTypeID=7 and [Values] like '%\%')

ROLLBACK TRAN