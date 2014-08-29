ALTER DATABASE [$(DatabaseName)]
    ADD LOG FILE (NAME = [REMIDB_log], FILENAME = '$(DefaultLogPath)$(DatabaseName)_log.ldf', MAXSIZE = 2097152 MB, FILEGROWTH = 51200 KB);

