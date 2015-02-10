BEGIN TRAN
DECLARE @LookupTypeID INT
DECLARE @LookupID INT

update Req.RequestType set HasIntegration=1 where RequestTypeID=1

INSERT INTO LookupType (Name, IsSystem) VALUES ('ConfigModes', 1)
INSERT INTO LookupType (Name, IsSystem) VALUES ('ConfigTypes', 1)

SELECT @LookupTypeID=LookupTypeID FROM LookupType WHERE Name='ConfigModes'
SELECT @LookupID = MAX(LookupID)+1 FROM Lookups

INSERT INTO Lookups (LookupID, IsActive, LookupTypeID, [Values]) VALUES (@LookupID, 1, @LookupTypeID, 'Developer')
SET @LookupID = @LookupID+1
INSERT INTO Lookups (LookupID, IsActive, LookupTypeID, [Values]) VALUES (@LookupID, 1, @LookupTypeID, 'Engineering')
SET @LookupID = @LookupID+1
INSERT INTO Lookups (LookupID, IsActive, LookupTypeID, [Values]) VALUES (@LookupID, 1, @LookupTypeID, 'Production')

SELECT @LookupTypeID=LookupTypeID FROM LookupType WHERE Name='ConfigTypes'
SET @LookupID = @LookupID+1
INSERT INTO Lookups (LookupID, IsActive, LookupTypeID, [Values]) VALUES (@LookupID, 1, @LookupTypeID, 'ProductConfigCommon')
SET @LookupID = @LookupID+1
INSERT INTO Lookups (LookupID, IsActive, LookupTypeID, [Values]) VALUES (@LookupID, 1, @LookupTypeID, 'StationConfigCommon')
SET @LookupID = @LookupID+1
INSERT INTO Lookups (LookupID, IsActive, LookupTypeID, [Values]) VALUES (@LookupID, 1, @LookupTypeID, 'TestConfigCommon')
SET @LookupID = @LookupID+1
INSERT INTO Lookups (LookupID, IsActive, LookupTypeID, [Values]) VALUES (@LookupID, 1, @LookupTypeID, 'SequenceConfigCommon')

ALTER TABLE Relab.ResultsInformation ADD ConfigID INT NULL
GO
CREATE TABLE [dbo].[Configurations](
	[ConfigID] [int] IDENTITY(1,1) NOT NULL,
	[ModeID] [int] NOT NULL,
	[Version] [nvarchar](50) NOT NULL,
	[ConfigTypeID] [int] NOT NULL,
	[Name] [nvarchar](150) NOT NULL,
	[Definition] [xml] NOT NULL,
 CONSTRAINT [PK_Configurations] PRIMARY KEY CLUSTERED 
(
	[ConfigID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Configurations]  WITH CHECK ADD  CONSTRAINT [FK_Configurations_Lookups] FOREIGN KEY([ConfigTypeID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[Configurations] CHECK CONSTRAINT [FK_Configurations_Lookups]
GO
ALTER TABLE [dbo].[Configurations]  WITH CHECK ADD  CONSTRAINT [FK_Configurations_Lookups1] FOREIGN KEY([ModeID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[Configurations] CHECK CONSTRAINT [FK_Configurations_Lookups1]
GO

INSERT INTO Menu (Name, Url) VALUES ('Versions', '/Relab/Versions.aspx')
INSERT INTO Menu (Name, Url) VALUES ('Measurements', '/Relab/Measurements.aspx')
INSERT INTO Menu (Name, Url) VALUES ('Graph', '/Relab/ResultGraph.aspx')
GO
DECLARE @MenuID INT
SELECT @MenuID=menuID FROM Menu WHERE Name='Versions'
insert into MenuDepartment (DepartmentID,MenuID)
select LookupID AS DepartmentID, @MenuID from Lookups where LookupTypeID=4 and IsActive=1

SELECT @MenuID=menuID FROM Menu WHERE Name='Measurements'
insert into MenuDepartment (DepartmentID,MenuID)
select LookupID AS DepartmentID, @MenuID from Lookups where LookupTypeID=4 and IsActive=1

SELECT @MenuID=menuID FROM Menu WHERE Name='Graph'
insert into MenuDepartment (DepartmentID,MenuID)
select LookupID AS DepartmentID, @MenuID from Lookups where LookupTypeID=4 and IsActive=1
GO

ROLLBACK TRAN