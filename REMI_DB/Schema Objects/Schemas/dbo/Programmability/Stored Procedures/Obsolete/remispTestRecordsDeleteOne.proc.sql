create PROCEDURE [dbo].[remispTestRecordsDeleteOne]
/*	'===============================================================
	'   NAME:                	remispTestRecordsDelete
	'   DATE CREATED:       	9 Oct 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: TestRecords OR the number of records in the table
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@TestName nvarchar(500),
@TestStageName nvarchar(500),
@qraNumber nvarchar(500),
@unitNumber int
	AS
	declare @trID int =(select id from testrecords where TestStageName = @TestStageName and TestName = @testname and TestUnitID = (select tu.ID from TestUnits as tu, Batches as b where b.QRANumber = @qranumber and tu.BatchID = b.ID and tu.BatchUnitNumber = @unitNumber))

delete from TestRecordsXTrackingLogs where TestRecordID = @trID

delete from testrecords where TestRecords.id = @trID

	    