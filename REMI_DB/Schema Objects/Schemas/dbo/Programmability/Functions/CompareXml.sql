ALTER FUNCTION [dbo].[CompareXml]
(
    @xml1 XML,
    @xml2 XML
)
RETURNS INT
AS 
BEGIN
    DECLARE @ret INT
    SELECT @ret = 0


    -- -------------------------------------------------------------
    -- If one of the arguments is NULL then we assume that they are
    -- not equal. 
    -- -------------------------------------------------------------
    IF @xml1 IS NULL OR @xml2 IS NULL 
    BEGIN
        RETURN 1
    END

    -- -------------------------------------------------------------
    -- Match the name of the elements 
    -- -------------------------------------------------------------
    IF  (SELECT @xml1.value('(local-name((/*)[1]))','VARCHAR(MAX)')) 
        <> 
        (SELECT @xml2.value('(local-name((/*)[1]))','VARCHAR(MAX)'))
    BEGIN
        RETURN 1
    END

     ---------------------------------------------------------------
     --Match the value of the elements
     ---------------------------------------------------------------
    IF((@xml1.query('count(/*)').value('.','INT') = 1) AND (@xml2.query('count(/*)').value('.','INT') = 1))
    BEGIN
    DECLARE @elValue1 VARCHAR(MAX), @elValue2 VARCHAR(MAX)

    SELECT
        @elValue1 = @xml1.value('((/*)[1])','VARCHAR(MAX)'),
        @elValue2 = @xml2.value('((/*)[1])','VARCHAR(MAX)')

    IF  @elValue1 <> @elValue2
    BEGIN
        RETURN 1
    END
    END

    -- -------------------------------------------------------------
    -- Match the number of attributes 
    -- -------------------------------------------------------------
    DECLARE @attCnt1 INT, @attCnt2 INT
    SELECT
        @attCnt1 = @xml1.query('count(/*/@*)').value('.','INT'),
        @attCnt2 = @xml2.query('count(/*/@*)').value('.','INT')

    IF  @attCnt1 <> @attCnt2 BEGIN
        RETURN 1
    END


    -- -------------------------------------------------------------
    -- Match the attributes of attributes 
    -- Here we need to run a loop over each attribute in the 
    -- first XML element and see if the same attribut exists
    -- in the second element. If the attribute exists, we
    -- need to check if the value is the same.
    -- -------------------------------------------------------------
    DECLARE @cnt INT, @cnt2 INT
    DECLARE @attName VARCHAR(MAX)
    DECLARE @attValue VARCHAR(MAX)

    SELECT @cnt = 1

    WHILE @cnt <= @attCnt1 
    BEGIN
        SELECT @attName = NULL, @attValue = NULL
        SELECT
            @attName = @xml1.value(
                'local-name((/*/@*[sql:variable("@cnt")])[1])', 
                'varchar(MAX)'),
            @attValue = @xml1.value(
                '(/*/@*[sql:variable("@cnt")])[1]', 
                'varchar(MAX)')

        -- check if the attribute exists in the other XML document
        IF @xml2.exist(
                '(/*/@*[local-name()=sql:variable("@attName")])[1]'
            ) = 0
        BEGIN
            RETURN 1
        END

        IF  @xml2.value(
                '(/*/@*[local-name()=sql:variable("@attName")])[1]', 
                'varchar(MAX)')
            <>
            @attValue
        BEGIN
            RETURN 1
        END

        SELECT @cnt = @cnt + 1
    END

    -- -------------------------------------------------------------
    -- Match the number of child elements 
    -- -------------------------------------------------------------
    DECLARE @elCnt1 INT, @elCnt2 INT
    SELECT
        @elCnt1 = @xml1.query('count(/*/*)').value('.','INT'),
        @elCnt2 = @xml2.query('count(/*/*)').value('.','INT')


    IF  @elCnt1 <> @elCnt2
    BEGIN
        RETURN 1
    END


    -- -------------------------------------------------------------
    -- Start recursion for each child element
    -- -------------------------------------------------------------
    SELECT @cnt = 1
    SELECT @cnt2 = 1
    DECLARE @x1 XML, @x2 XML
    DECLARE @noMatch INT

    WHILE @cnt <= @elCnt1 
    BEGIN

        SELECT @x1 = @xml1.query('/*/*[sql:variable("@cnt")]')
    --RETURN CONVERT(VARCHAR(MAX),@x1)
    WHILE @cnt2 <= @elCnt2
    BEGIN
        SELECT @x2 = @xml2.query('/*/*[sql:variable("@cnt2")]')
        SELECT @noMatch = dbo.CompareXml( @x1, @x2 )
        IF @noMatch = 0 BREAK
        SELECT @cnt2 = @cnt2 + 1
    END

    SELECT @cnt2 = 1

        IF @noMatch = 1
        BEGIN
            RETURN 1
        END

        SELECT @cnt = @cnt + 1
    END

    RETURN @ret
END