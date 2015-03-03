begin tran
CREATE TABLE [Relab].[ResultsXML](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ResultID] [int] NOT NULL,
	[ResultXML] [xml] NOT NULL,
	[VerNum] [int] NOT NULL,
	[isProcessed] [int] NULL,
	[StationName] [nvarchar](400) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[lossFile] [xml] NULL,
 CONSTRAINT [PK_Relab.ResultXML] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [Relab].[ResultsXML]  WITH CHECK ADD  CONSTRAINT [FK_ResultXML_Results] FOREIGN KEY([ResultID])
REFERENCES [Relab].[Results] ([ID])
GO

ALTER TABLE [Relab].[ResultsXML] CHECK CONSTRAINT [FK_ResultXML_Results]
GO

ALTER TABLE [Relab].[ResultsXML] ADD  DEFAULT ((0)) FOR [isProcessed]
GO
delete from Relab.ResultsParameters
delete from Relab.ResultsMeasurements
GO
DBCC CHECKIDENT ([relab.ResultsXML], reseed, 1)
GO
DBCC CHECKIDENT ([Relab.ResultsParameters], reseed, 1)
GO
DBCC CHECKIDENT ([Relab.ResultsMeasurements], reseed, 1)
GO
CREATE PRIMARY XML INDEX [ResultXMLIndex] ON [Relab].[ResultsXML] 
(
	[ResultXML]
)WITH (PAD_INDEX  = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO
DECLARE @RowID INT
DECLARE @ResultID INT

select ROW_NUMBER() OVER (ORDER BY r.ID) AS RowID, r.VerNum, r.ResultsXML, r.TestStageID, r.TestUnitID, r.TestID, 
	(SELECT MIN(r2.ID) FROM Relab.Results r2 WHERE r.TestStageID=r2.TestStageID AND r.TestUnitID=r2.TestUnitID AND r.TestID=r2.TestID) AS ResultID
into #temp
from Relab.Results r
order by r.TestStageID, r.TestUnitID, r.TestID

insert into relab.ResultsXML (ResultID, ResultXML, VerNum)
select ResultID, ResultsXML As ResultXML, VerNum from #temp

drop table #temp
GO
IF  EXISTS (SELECT * FROM dbo.sysobjects where name ='DF__Results__IsProce__7C255952' AND type = 'D')
BEGIN
	ALTER TABLE [Relab].[Results] DROP CONSTRAINT [DF__Results__IsProce__7C255952]
END
GO
ALTER TABLE Relab.Results DROP Column ResultsXML
GO
ALTER TABLE Relab.Results DROP Column VerNum
GO
ALTER TABLE Relab.Results DROP Column IsProcessed
GO
ALTER TABLE Relab.Results DROP Column StartDate
GO
ALTER TABLE Relab.Results DROP Column EndDate
GO
DROP TABLE Relab.ResultsHeader
GO
delete from Relab.Results where ID not in (select resultid from Relab.ResultsXML)
GO
ALTER TABLE Relab.ResultsMeasurements ADD ReTestNum INT NOT NULL
GO
ALTER TABLE Relab.ResultsMeasurements ADD Archived BIT DEFAULT(0) NOT NULL
GO
alter table Relab.ResultsMeasurements add XMLID INT NOT NULL
go
drop procedure relab.remispGetMeasurementsByTestStage
go
drop procedure Relab.remispGetUnitsByTestStageMeasurement
GO
drop procedure Relab.remispResultsHeaders
GO
rollback tran
