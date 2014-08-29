/*
SELECT ID, ResultMeasurementID, [File], FileName, ContentType
INTO NewTable
FROM Relab.ResultsMeasurementsFiles

alter table NewTable Add NewFile  VarBinary(max)
*/

ALTER PROCEDURE Relab.GetAllImages
AS
BEGIN
	SELECT TOP 2000 ID, ResultMeasurementID,  [File], CASE WHEN FileName LIKE '%/%' THEN REPLACE(FileName, LEFT(FileName, abs(charindex('/', reverse(FileName)) - len(FileName)-1)), '') ELSE REPLACE(FileName, LEFT(FileName, abs(charindex('\', reverse(FileName)) - len(FileName)-1)), '') END AS FileName,
	REPLACE(UPPER(ContentType), '.','') AS ContentType
	FROM NewTable
	WHERE NewFile IS NULL
END
GO
GRANT EXECUTE ON Relab.GetAllImages TO Remi
GO
ALTER PROCEDURE [Relab].ImageFix @File VARBINARY(MAX), @ID INT
AS
BEGIN
	IF (DATALENGTH(@File) > 0)
	BEGIN
		UPDATE NewTable SET NewFile=@File WHERE ID=@ID
	END
END
GO
GRANT EXECUTE ON Relab.ImageFix TO Remi
GO

select COUNT(*)
--select *, DATALENGTH([File]), DATALENGTH(newFile) 
FROM NewTable 
where newFile iS NOT NULL



select * from NewTable 


select * from Relab.ResultsMeasurements where resultid=25016 and ID in (select Relab.ResultsMeasurementsFiles.ResultMeasurementID from Relab.ResultsMeasurementsFiles)