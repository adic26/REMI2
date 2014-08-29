--EXECUTE sp_addrolemember @rolename = N'remi_web', @membername = N'remi';


GO
EXECUTE sp_addrolemember @rolename = N'db_owner', @membername = N'RIMNET\ogaudreault';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'remi_web';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'RIMNET\wfahmy';


GO
EXECUTE sp_addrolemember @rolename = N'db_datawriter', @membername = N'remi_web';

