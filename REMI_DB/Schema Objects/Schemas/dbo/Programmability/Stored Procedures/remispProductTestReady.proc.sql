ALTER PROCEDURE remispProductTestReady @ProductID INT, @MNum NVARCHAR(3)
AS
BEGIN
	DECLARE @PSID AS INT = (SELECT ID FROM ProductSettings WHERE KeyName=@MNum AND ProductID=@ProductID)
	
	SELECT t.TestName, @MNum AS M, CASE ptr.IsReady WHEN 1 THEN 'Yes' WHEN 2 THEN 'No' WHEN 3 THEN 'N/A' ELSE '' END AS IsReady, 
		ptr.Comment, t.Owner, t.Trainee, t.ID As TestID, ptr.ID As ReadyID, @PSID As PSID,
		CASE ptr.IsNestReady WHEN 1 THEN 'Yes' WHEN 2 THEN 'No' WHEN 3 THEN 'N/A' ELSE '' END AS IsNestReady, CASE WHEN JIRA = 0 THEN NULL ELSE JIRA END AS JIRA
	FROM Tests t
		LEFT OUTER JOIN ProductTestReady ptr ON ptr.TestID=t.ID AND ptr.ProductID=@ProductID AND ptr.PSID=@PSID
	WHERE t.TestName IN ('Parametric Radiated Wi-Fi','Acoustic Test', 'HAC Test', 'Sensor Test',
		'Touch Panel Test','Insertion','Top Facing Keys Tactility Test','Peripheral Keys Tactility Test','Charging Test',
		'Camera Front','Bluetooth Test','Accessory Charging','Accessory Acoustic Test','Radiated RF Test','KET Top Facing Keys Cycling Test',
		'Slider Test','Altimeter Test','Mechanical Over Extention')
		AND ISNULL(t.IsArchived, 0) = 0
	ORDER BY t.TestName
END
GO
GRANT EXECUTE ON remispProductTestReady TO REMI
GO