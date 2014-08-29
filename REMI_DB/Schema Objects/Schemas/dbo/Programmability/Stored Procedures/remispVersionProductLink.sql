alter PROCEDURE remispVersionProductLink @Application nvarchar(50), @PCNameID INT
AS
BEGIN
	SELECT a.ID, av.ID AS VerID, av.VerNum, av.ApplicableToAll,
	ISNULL((
		SELECT pcv.VersionNum
		FROM ApplicationProductVersion apv
			INNER JOIN ProductConfigurationVersion pcv ON pcv.ID=apv.PCVID
			INNER JOIN ProductConfigurationUpload pcu ON pcu.ID=pcv.UploadID AND pcu.ID=@PCNameID
		WHERE apv.AppVersionID = av.id
	),0) As PCVersion,
	(
		SELECT pcv.ID
		FROM ApplicationProductVersion apv
			INNER JOIN ProductConfigurationVersion pcv ON pcv.ID=apv.PCVID
			INNER JOIN ProductConfigurationUpload pcu ON pcu.ID=pcv.UploadID AND pcu.ID=@PCNameID
		WHERE apv.AppVersionID = av.id
	) As PCVersionID,
	(
		SELECT apv.ID
		FROM ApplicationProductVersion apv
			INNER JOIN ProductConfigurationVersion pcv ON pcv.ID=apv.PCVID
			INNER JOIN ProductConfigurationUpload pcu ON pcu.ID=pcv.UploadID AND pcu.ID=@PCNameID
		WHERE apv.AppVersionID = av.id
	) As APVID
	FROM Applications a
		INNER JOIN ApplicationVersions av ON a.ID=av.AppID
	WHERE a.ApplicationName=@Application
END
GO
grant execute on remispVersionProductLink to remi
GO