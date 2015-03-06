ALTER PROCEDURE remispMenuAccessByDepartment @Name NVARCHAR(150) = NULL, @DepartmentID INT = NULL
AS
BEGIN
	SELECT '' AS Name, '' AS Department, '' AS Url, 0 AS MenuID, 0 AS MenuDepartmentID
	UNION
	SELECT m.Name, l.[Values] AS Department, m.Url, m.MenuID, md.MenuDepartmentID
	FROM Menu m
		INNER JOIN MenuDepartment md ON m.MenuID=md.MenuID
		INNER JOIN Lookups l ON l.LookupID=md.DepartmentID
	WHERE (md.DepartmentID = @DepartmentID OR ISNULL(@DepartmentID, 0) = 0)
		AND (m.Name=@Name OR LTRIM(RTRIM(ISNULL(@Name, '')))  = '')
	ORDER BY 2, 1
END
GO
GRANT EXECUTE ON remispMenuAccessByDepartment TO REMI
GO