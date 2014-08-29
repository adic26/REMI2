-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TestsAuditInsertUpdate]
	ON  [dbo].[Tests]
	after insert,update
AS 
BEGIN
	SET NOCOUNT ON;
	Declare @action char(1)
	DECLARE @count INT
  
	--check if this is an insert or an update

	If Exists(Select * From Inserted) and Exists(Select * From Deleted) --Update, both tables referenced
	BEGIN
		Set @action= 'U'
	END
	ELSE
		BEGIN
			If Exists(Select * From Inserted) --insert, only one table referenced
			BEGIN
				Set @action= 'I'
			END
			if not Exists(Select * From Inserted) and not Exists(Select * From Deleted)--nothing changed, get out of here
			BEGIN
				RETURN
			END
		END

		--Only inserts records into the Audit table if the row was either updated or inserted and values actually changed.
		select @count= count(*) from
		(
		   select TestName, Duration, TestType, WILocation, Comment, ResultBasedOnTime, DegradationVal from Inserted
		   except
		   select TestName, Duration, TestType, WILocation, Comment, ResultBasedOnTime, DegradationVal from Deleted
		) a

		IF ((@count) >0)
		BEGIN
			insert into Testsaudit (TestId, TestName, Duration, TestType, WILocation, Comment, ResultBasedOnTime, UserName, Action, DegradationVal)
				Select Id, TestName, Duration, TestType, WILocation, Comment, ResultBasedOnTime, LastUser, @action, DegradationVal from inserted
		END
	END