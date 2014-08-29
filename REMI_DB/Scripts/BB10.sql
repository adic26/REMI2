DECLARE @Debug INT
DECLARE @BB10Products TABLE (ProductGroupName NVARCHAR(800))
DECLARE @NonBB10Products TABLE (ProductGroupName NVARCHAR(800))
SET @Debug = 1

BEGIN TRANSACTION

INSERT INTO @BB10Products (ProductGroupName)
SELECT 'Aristo R081' union
SELECT 'Colt R061' union
SELECT 'Laguna R069' union
SELECT 'Naples' union
SELECT 'Nashville' union
SELECT 'Nevada' union
SELECT 'Rainier R092' union
SELECT 'Lisbon R070' union
SELECT 'London R072' union
SELECT 'Winchester 2 R051' union
SELECT 'Rainier R093' union
SELECT 'Liverpool R086' union
SELECT 'Winchester 2 R052' union
SELECT 'Winchester 2 R053' union
SELECT 'Astro R089' union
SELECT 'Anisio R096' union
SELECT 'Agosto R104'

INSERT INTO @NonBB10Products (ProductGroupName) SELECT '3G SIMs' UNION
SELECT 'Apollo' UNION
SELECT 'Armstrong R049' UNION
SELECT 'BabyBear' UNION
SELECT 'Bellagio' UNION
SELECT 'Battery' UNION
SELECT 'Dakota' UNION
SELECT 'Davis R050' UNION
SELECT 'Essex' UNION
SELECT 'Gemini' UNION
SELECT 'Jennings' UNION
SELECT 'Kepler' UNION
SELECT 'Knight R047' UNION
SELECT 'Live SIMs' UNION
SELECT 'Monaco R008' UNION
SELECT 'Montana' UNION
SELECT 'Non-RIM Device' UNION
SELECT 'Not Product Specific' UNION
SELECT 'Onyx' UNION
SELECT 'Oxford' UNION
SELECT 'Prescott' UNION
SELECT 'Sedona' UNION
SELECT 'Test SIMs' UNION
SELECT 'Travel Charger' UNION
SELECT 'USB Cable' UNION
SELECT 'Wynton R064' UNION
SELECT 'Monza 1256' UNION
SELECT 'Monza 148' UNION
SELECT 'Orion' UNION
SELECT 'Orlando' UNION
SELECT 'Talladega'


UPDATE ProductSettings SET DefaultValue='true', LastUser='ogaudreault' WHERE KeyName='IsBBX' AND DefaultValue='false'

UPDATE ProductSettings
SET ValueText='true', LastUser='ogaudreault'
where ProductGroupName IN (SELECT ProductGroupName FROM @BB10Products) AND KeyName='IsBBX' AND ValueText <> 'true'

UPDATE ProductSettings
SET ValueText='false', LastUser='ogaudreault'
WHERE ProductGroupName IN (SELECT ProductGroupName FROM @NonBB10Products) AND KeyName='IsBBX' AND ValueText <> 'false'

INSERT INTO ProductSettings (LastUser, ProductGroupName, KeyName, ValueText, DefaultValue)
SELECT 'ogaudreault', ProductGroupName, 'IsBBX', 'false', 'true'
FROM @NonBB10Products
WHERE ProductGroupName NOT IN (SELECT ProductGroupName FROM ProductSettings WHERE KeyName='IsBBX')

SELECT *
FROM ProductSettings
WHERE KeyName='IsBBX'
ORDER BY ValueText

--select distinct productgroupname
--from Batches
--where QRANumber like 'qra-12%'
--and ProductGroupName not in (select ProductGroupName from ProductSettings where KeyName='IsBBX')
--order by ProductGroupName

IF (@Debug=1)
BEGIN
	ROLLBACK TRANSACTION
	PRINT 'ROLLBACK TRANSACTION'
END
ELSE
BEGIN
	COMMIT TRANSACTION
	PRINT 'COMMIT TRANSACTION'
END