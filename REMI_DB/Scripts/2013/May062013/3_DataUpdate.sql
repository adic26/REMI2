BEGIN TRAN

ALTER TABLE ProductManagersAudit ALTER COLUMN _ProductManagerName NVARCHAR(255) NULL
GO

UPDATE ProductManagers
SET ProductManagers.UserID=Users.ID
FROM ProductManagers
INNER JOIN Users ON ProductManagers._UserName=Users.LDAPLogin
GO
ALTER TABLE ProductManagers ALTER COLUMN _UserName NVARCHAR(255) NULL
GO
ALTER TABLE ProductManagers ALTER COLUMN UserID INT NOT NULL
GO

UPDATE ProductManagersAudit
SET ProductManagersAudit.UserID=Users.ID
FROM ProductManagersAudit
INNER JOIN Users ON ProductManagersAudit._ProductManagerName=Users.LDAPLogin
GO

UPDATE UserTraining
SET UserTraining.UserID=Users.ID
FROM UserTraining
INNER JOIN Users ON UserTraining._UserName=Users.LDAPLogin
GO
ALTER TABLE UserTraining ALTER COLUMN UserID INT NOT NULL
GO
ALTER TABLE UserTraining ALTER COLUMN _UserName NVARCHAR(255) NULL
GO
update users
set TestCentreID=lookupid
from Users
inner join Lookups on Type='TestCenter' and [Values]=_TestCentre
GO
update usersaudit
set TestCentreID=lookupid
from usersaudit
inner join Lookups on Type='TestCenter' and [Values]=_TestCentre
GO
ROLLBACK TRAN