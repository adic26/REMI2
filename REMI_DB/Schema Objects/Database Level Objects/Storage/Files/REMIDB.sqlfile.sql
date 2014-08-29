ALTER DATABASE [$(DatabaseName)]
    ADD FILE (NAME = [REMIDB], FILENAME = '$(DefaultDataPath)$(DatabaseName).mdf', FILEGROWTH = 102400 KB) TO FILEGROUP [PRIMARY];

