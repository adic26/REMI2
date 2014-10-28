begin tran
go
CREATE TABLE [dbo].[LookupType](
	[LookupTypeID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](150) NOT NULL,
 CONSTRAINT [PK_LookupType] PRIMARY KEY CLUSTERED 
(
	[LookupTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
go
insert into LookupType (Name)
select distinct [type]
from Lookups

ALTER TABLE Lookups Add LookupTypeID INT NULL
GO
ALTER TABLE [dbo].[Lookups]  WITH CHECK ADD  CONSTRAINT [FK_Lookups_LookupType] FOREIGN KEY([LookupTypeID])
REFERENCES [dbo].[LookupType] ([LookupTypeID])
GO

ALTER TABLE [dbo].[Lookups] CHECK CONSTRAINT [FK_Lookups_LookupType]
GO

UPDATE l
SET l.LookupTypeID=lt.LookupTypeID
FROM Lookups l
INNER JOIN LookupType lt ON lt.Name=l.[Type]
go
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Lookups]') AND name = N'UX_Lookups_TypeVal')
DROP INDEX [UX_Lookups_TypeVal] ON [dbo].[Lookups] WITH ( ONLINE = OFF )
GO

/****** Object:  Index [UX_Lookups_TypeVal]    Script Date: 10/28/2014 11:35:05 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Lookups_TypeVal] ON [dbo].[Lookups] 
(
	[LookupTypeID] ASC,
	[Values] ASC,
	[ParentID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
Alter table lookups drop column [type]

CREATE UNIQUE NONCLUSTERED INDEX [UX_LookupType_Name] ON [dbo].[LookupType] 
(
	[Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

insert into Relab.ResultsInformation (Name, Value, XMLID, IsArchived)
select l.[Values] As Name, m.MeasurementValue, m.XMLID, m.Archived 
from Relab.ResultsMeasurements m
inner join Lookups l on m.MeasurementTypeID=l.LookupID
where MeasurementTypeID in (select lookupid from Lookups WHERE [Values] in ('Start','Start UTC','End','End UTC', 'OS','OSVersion','OS Version')) order by resultid

--parameters
select *
into ResultsParameters_BAK
from Relab.ResultsParameters
where ResultMeasurementID in (select ID from Relab.ResultsMeasurements where MeasurementTypeID in (select lookupid from Lookups WHERE [Values] in ('Start','Start UTC','End','End UTC', 'OS','OSVersion','OS Version')) )

delete from Relab.ResultsParameters
where ResultMeasurementID in (select ID from Relab.ResultsMeasurements where MeasurementTypeID in (select lookupid from Lookups WHERE [Values] in ('Start','Start UTC','End','End UTC', 'OS','OSVersion','OS Version')) )

--audit
select *
into ResultsMeasurementsAudit_BAK
from Relab.ResultsMeasurementsAudit
where ResultMeasurementID in (select ID from Relab.ResultsMeasurements where MeasurementTypeID in (select lookupid from Lookups WHERE [Values] in ('Start','Start UTC','End','End UTC', 'OS','OSVersion','OS Version')) )

delete from Relab.ResultsMeasurementsAudit
where ResultMeasurementID in (select ID from Relab.ResultsMeasurements where MeasurementTypeID in (select lookupid from Lookups WHERE [Values] in ('Start','Start UTC','End','End UTC', 'OS','OSVersion','OS Version')) )

--measurements
select *
into ResultsMeasurements_BAK
from Relab.ResultsMeasurements where MeasurementTypeID in (select lookupid from Lookups WHERE [Values] in ('Start','Start UTC','End','End UTC', 'OS','OSVersion','OS Version')) 

delete from Relab.ResultsMeasurements where MeasurementTypeID in (select lookupid from Lookups WHERE [Values] in ('Start','Start UTC','End','End UTC', 'OS','OSVersion','OS Version')) 


rollback tran