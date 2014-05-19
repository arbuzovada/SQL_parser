CREATE FUNCTION [dbo].[Split]
(
    @ItemList NVARCHAR(MAX), 
    @delimiter CHAR(1)
)
RETURNS @ItemTable TABLE (Item VARCHAR(250))  
AS      

BEGIN    
    DECLARE @tempItemList NVARCHAR(MAX)
    SET @tempItemList = @ItemList

    DECLARE @i INT    
    DECLARE @Item NVARCHAR(4000)

    --SET @tempItemList = REPLACE (@tempItemList, ' ', '')
    SET @i = CHARINDEX(@delimiter, @tempItemList)

    WHILE (LEN(@tempItemList) > 0)
    BEGIN
        IF @i = 0
            SET @Item = @tempItemList
        ELSE
            SET @Item = LEFT(@tempItemList, @i - 1)
        INSERT INTO @ItemTable(Item) VALUES(@Item)
        IF @i = 0
            SET @tempItemList = ''
        ELSE
            SET @tempItemList = RIGHT(@tempItemList, LEN(@tempItemList) - @i)
        SET @i = CHARINDEX(@delimiter, @tempItemList)
    END 
    RETURN
END