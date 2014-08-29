CREATE PROCEDURE [dbo].[remispJobsSelectList]
/*	'===============================================================
	'   NAME:                	remispJobsSelectList
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: Jobs 
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
		'===============================================================*/
	AS SELECT 
		ID,
		JobName, 
		WILocation,
		Comment,
		LastUser,
		ConcurrencyID,
		OperationsTest,
		TechnicalOperationsTest,
		MechanicalTest
	
	FROM Jobs order by JobName
