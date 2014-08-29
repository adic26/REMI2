CREATE VIEW dbo.remivwLastLogs
AS
with TestData as
( select 
         row_number() over
         ( partition by testunitID order by intime desc
         ) as Seq,
      dtl.*
  from DeviceTrackingLog as dtl
)
select *
from TestData
where seq = 1
