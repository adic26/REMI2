ALTER PROCEDURE [dbo].[remispBatchGetViewBatch] @qranumber nvarchar(11)
AS
DECLARE @BatchID INT
SELECT @BatchID=ID FROM Batches WITH(NOLOCK) WHERE QRANumber=@qranumber

EXEC Remispbatchesselectbyqranumber @QraNumber; 

EXEC remispBatchGetTaskInfo @BatchID; 

EXEC Remisptestrecordsselectforbatch @qranumber;

EXEC Remisptestunitssearchfor @qranumber;  

GO
GRANT EXECUTE ON remispBatchGetViewBatch TO Remi
GO