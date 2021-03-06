
begin tran
set nocount on
delete from TestExceptions where OldID is not null

DECLARE @ProductGroupName NVARCHAR(400)
DECLARE @ReasonForRequest INT
DECLARE @TestUnitID INT
DECLARE @TestStageID INT
DECLARE @TestName NVARCHAR(400)
DECLARE @ExceptionID INT
DECLARE @LookupID INT
DECLARE @TestID INT
DECLARE @OldID INT
DECLARE @LastUser NVARCHAR(255)
declare @counting int
declare @hotmany int
set @hotmany = 0
SET @ExceptionID = (SELECT ISNULL(MAX(ID),0)+1 FROM TestExceptions)

DECLARE insert_cursor CURSOR FOR SELECT ID, ProductGroupName, ReasonForRequest, TestUnitID, TestStageID, TestName, LastUser,
(SELECT COUNT(*) FROM Tests WHERE Tests.TestName=_TestExceptions.TestName) as counting FROM _TestExceptions ORDER BY ID
OPEN insert_cursor

FETCH NEXT FROM insert_cursor INTO @OldID, @ProductGroupName, @ReasonForRequest,@TestUnitID,@TestStageID,@TestName, @LastUser,@counting

WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @testshouldinsert INT
	set @testshouldinsert = 1

	IF (@TestName IS NOT NULL)
	BEGIN
			SET @TestID = NULL
			print @counting
			IF (@counting > 1 AND @TestStageID IS NOT NULL AND EXISTS (SELECT TestID FROM TestStages WHERE ID=@TestStageID AND TestID IS NOT NULL))
			begin
				print 'in teststages look for tests'
				SET @TestID = CONVERT(NVARCHAR,(SELECT TestID FROM TestStages WHERE ID=@TestStageID AND TestID IS NOT NULL))
			end
			else IF (@counting = 1)
			begin
				select @TestID = ID FROM Tests WHERE TestName=@TestName
			end
			else
			begin
				set @testshouldinsert = 0
				set @hotmany = @hotmany + 1
			end
	END
	
	if @testshouldinsert =1 --meaning test was found so it was inserted and the remaining exceptions should insert
	begin
		IF (@TestID IS NOT NUll)
		BEGIN
			SET @LookupID = (SELECT LookupID FROM Lookups WHERE [Values]='Test' AND Type='Exceptions')
			
			IF NOT EXISTS (SELECT 1 FROM TestExceptions WHERE ID = @ExceptionID AND LookupID = @LookupID)
			BEGIN
				INSERT INTO TestExceptions (ID, LookupID, Value, OldID, LastUser) 
				VALUES (@ExceptionID, @LookupID, @TestID, @OldID, @LastUser)
			END
		END
		
		IF (@ProductGroupName IS NOT NULL)
		BEGIN
			SET @LookupID = (SELECT LookupID FROM Lookups WHERE [Values]='ProductGroupName' AND Type='Exceptions')
			IF NOT EXISTS (SELECT 1 FROM TestExceptions WHERE ID = @ExceptionID AND LookupID = @LookupID)
			BEGIN
				INSERT INTO TestExceptions (ID, LookupID, Value, OldID, LastUser) VALUES (@ExceptionID, @LookupID, @ProductGroupName, @OldID, @LastUser)
			END
		END
		
		IF (@TestUnitID IS NOT NULL)
		BEGIN
			SET @LookupID = (SELECT LookupID FROM Lookups WHERE [Values]='TestUnitID' AND Type='Exceptions')
			IF NOT EXISTS (SELECT 1 FROM TestExceptions WHERE ID = @ExceptionID AND LookupID = @LookupID)
			BEGIN
				INSERT INTO TestExceptions (ID, LookupID, Value, OldID, LastUser) VALUES (@ExceptionID, @LookupID, @TestUnitID, @OldID, @LastUser)
			END
		END
		
		IF (@TestStageID IS NOT NULL)
		BEGIN
			SET @LookupID = (SELECT LookupID FROM Lookups WHERE [Values]='TestStageID' AND Type='Exceptions')
			IF NOT EXISTS (SELECT 1 FROM TestExceptions WHERE ID = @ExceptionID AND LookupID = @LookupID)
			BEGIN
				INSERT INTO TestExceptions (ID, LookupID, Value, OldID, LastUser) VALUES (@ExceptionID, @LookupID, @TestStageID, @OldID, @LastUser)
			END
		END
		
		IF (@ReasonForRequest IS NOT NULL)
		BEGIN
			SET @LookupID = (SELECT LookupID FROM Lookups WHERE [Values]='ReasonForRequest' AND Type='Exceptions')
			IF NOT EXISTS (SELECT 1 FROM TestExceptions WHERE ID = @ExceptionID AND LookupID = @LookupID)
			BEGIN
				INSERT INTO TestExceptions (ID, LookupID, Value, OldID, LastUser) VALUES (@ExceptionID, @LookupID, @ReasonForRequest, @OldID, @LastUser)
			END
		END
	END
	
	set @counting = 0
	FETCH NEXT FROM insert_cursor INTO @OldID, @ProductGroupName, @ReasonForRequest,@TestUnitID,@TestStageID,@TestName,@LastUser,@counting
	SET @ExceptionID = @ExceptionID +1
END

CLOSE insert_cursor
DEALLOCATE insert_cursor

select @hotmany

select oldid, COUNT(*)
from TestExceptions
where OldID is not null
group by oldid
having COUNT(*) = 1



set nocount off



commit tran