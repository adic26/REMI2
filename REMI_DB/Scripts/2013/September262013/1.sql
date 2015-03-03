/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 9/23/2013 1:08:03 PM

*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO
PRINT N'Altering [dbo].[Jobs]'
GO
ALTER TABLE [dbo].[Jobs] ADD
[IsActive] [bit] NULL CONSTRAINT [DF__Jobs__IsActive__194BA7E5] DEFAULT ((1))
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispJobsSelectSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispJobsSelectSingleItem] @ID int = null, @JobName nvarchar(300) = null
AS
BEGIN
	SELECT ID, JobName, WILocation, Comment, LastUser, ConcurrencyID, OperationsTest, TechnicalOperationsTest, MechanicalTest, ProcedureLocation, ISNULL(IsActive, 0) AS IsActive
	FROM Jobs
	WHERE 
		(
			(@ID > 0 and @JobName is null) 
			and ID = @ID
		) 
		OR 
		(
			(@ID is null and @JobName is not null) 
			and JobName = @JobName
		)
		OR
		(
			@ID IS NULL AND @JobName IS NULL AND ISNULL(IsActive, 0) = 1
		)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispJobsInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispJobsInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispJobsInsertUpdateSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: Jobs
    '   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int OUTPUT,
	@JobName nvarchar(400),
	@WILocation nvarchar(400)=null,
	@Comment nvarchar(1000)=null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@OperationsTest bit = 0,
	@TechOperationsTest bit = 0,
	@MechanicalTest bit = 0,
	@ProcedureLocation nvarchar(400)=null,
	@IsActive bit = 0
	AS

	DECLARE @ReturnValue int
	
	set @ID = (select ID from Jobs where jobs.JobName=@JobName)
	
	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO Jobs(JobName, WILocation, Comment, LastUser, OperationsTest, TechnicalOperationsTest, MechanicalTest, ProcedureLocation, IsActive)
		VALUES(@JobName, @WILocation, @Comment, @LastUser, @OperationsTest, @TechOperationsTest, @MechanicalTest, @ProcedureLocation, @IsActive)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Jobs SET
			JobName = @JobName, 
			LastUser = @LastUser,
			Comment = @Comment,
			WILocation = @WILocation,
			OperationsTest = @OperationsTest,
			TechnicalOperationsTest = @TechOperationsTest,
			MechanicalTest = @MechanicalTest,
			ProcedureLocation = @ProcedureLocation,
			IsActive = @IsActive
		WHERE ID = @ID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Jobs WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[JobsAudit]'
GO
ALTER TABLE [dbo].[JobsAudit] ADD
[IsActive] [bit] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[JobsAuditDelete] on [dbo].[Jobs]'
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[JobsAuditDelete]
   ON  dbo.Jobs
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into jobsaudit (JobId, JobName, WILocation, Comment, UserName, Action, ProcedureLocation, IsActive)
Select ID, JobName, WILocation, Comment, LastUser, 'D', ProcedureLocation, IsActive from deleted

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[JobsAuditInsertUpdate] on [dbo].[Jobs]'
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[JobsAuditInsertUpdate]
   ON  dbo.Jobs
    after insert,update
AS 
BEGIN
	SET NOCOUNT ON;
 
	Declare @action char(1)
	DECLARE @count INT
	 
	--check if this is an insert or an update

	If Exists(Select * From Inserted) and Exists(Select * From Deleted) --Update, both tables referenced
	begin
		Set @action= 'U'
	end
	else
	begin
		If Exists(Select * From Inserted) --insert, only one table referenced
		Begin
			Set @action= 'I'
		end
		if not Exists(Select * From Inserted) and not Exists(Select * From Deleted)--nothing changed, get out of here
		Begin
			RETURN
		end
	end

	--Only inserts records into the Audit table if the row was either updated or inserted and values actually changed.
	select @count= count(*) from
	(
	   select JobName, WILocation, Comment, ProcedureLocation, IsActive from Inserted
	   except
	   select JobName, WILocation, Comment, ProcedureLocation, IsActive from Deleted
	) a

	if ((@count) >0)
	begin
		insert into jobsaudit (JobId, JobName, WILocation, Comment, UserName, jobsaudit.Action, ProcedureLocation, IsActive)
		Select ID, JobName, WILocation, Comment, LastUser, @Action, ProcedureLocation, IsActive 
		from inserted
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
UPDATE Jobs SET IsActive=1 WHERE JobName LIKE 'T0%' OR JobName LIKE 'T1%'
GO
UPDATE Jobs SET IsActive=0 WHERE IsActive IS NULL
GO
update Jobs set IsActive=0 where ID=195 and JobName like 'T038%'
GO
update Jobs set IsActive=0 where ID=185 and jobname like 'T043%'
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
rollback TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO