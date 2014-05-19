DECLARE @publ_ID int,
	@dup_ID int,
	@journal_ID int,
	@author_ID int,
	@SC_ID int,
	@max_year int,
	@cur int,
	@publ_year int,
	@author varchar(1500),
	@all_authors varchar(1500),
	@publ varchar(1500),
	@publ_stat varchar(1500),
	@journal varchar(1500),
	@journal_name varchar(1500),
	@SC_stat varchar(1500),
	@temp varchar(1500),
	@SC varchar(1500),
	@country varchar(1500),
	@cur_SC varchar(1500),
	@KW1 varchar(1500),
	@KW2 varchar(1500),
	@KW varchar(1500),
	@pos int,
	@res int;

-- Authors --
DROP TABLE Prac3.dbo.authors;
CREATE TABLE Prac3.dbo.authors (ID int IDENTITY(1, 1) PRIMARY KEY WITH (IGNORE_DUP_KEY = ON),
	name varchar(255) UNIQUE);
DROP TABLE Prac3.dbo.A_P;
CREATE TABLE Prac3.dbo.A_P (author_ID int , publ_ID int);

-- Scientific centers --
DROP TABLE Prac3.dbo.SC;
CREATE TABLE Prac3.dbo.SC (ID int IDENTITY(1, 1) PRIMARY KEY WITH (IGNORE_DUP_KEY = ON),
	SC varchar(255));--, country varchar(255));
DROP TABLE Prac3.dbo.SC_P;
CREATE TABLE Prac3.dbo.SC_P (SC_ID int , publ_ID int);
DROP TABLE Prac3.dbo.SC_P_count;
CREATE TABLE Prac3.dbo.SC_P_count (SC_ID int UNIQUE, npubl int);

-- Journals --
DROP TABLE Prac3.dbo.journals;
CREATE TABLE Prac3.dbo.journals (ID int IDENTITY(1, 1) PRIMARY KEY WITH (IGNORE_DUP_KEY = ON),
	name varchar(255));
DROP TABLE Prac3.dbo.J_P;
CREATE TABLE Prac3.dbo.J_P (journal_ID int, publ_ID int);
DROP TABLE Prac3.dbo.J_P_count;
CREATE TABLE Prac3.dbo.J_P_count (journal_ID int, npubl int);
--DROP TABLE Prac3.dbo.J_P_year;
CREATE TABLE Prac3.dbo.J_P_year (journal_ID int, npubl int, publ_year int);
DROP TABLE Prac3.dbo.J_P_count_name;
CREATE TABLE Prac3.dbo.J_P_count_name (journal_name varchar(255), npubl int);
DROP TABLE Prac3.dbo.J_P_count_5last;
CREATE TABLE Prac3.dbo.J_P_count_5last (journal_ID int, npubl int);
DROP TABLE Prac3.dbo.J_P_count_5last_name;
CREATE TABLE Prac3.dbo.J_P_count_5last_name (journal_name varchar(255), npubl int);
DROP TABLE Prac3.dbo.J_A;
CREATE TABLE Prac3.dbo.J_A (journal_ID int, author_ID int);
DROP TABLE Prac3.dbo.J_A_count;
CREATE TABLE Prac3.dbo.J_A_count (journal_ID int, nauthors int);
DROP TABLE Prac3.dbo.J_A_count_name;
CREATE TABLE Prac3.dbo.J_A_count_name (journal_name varchar(255), nauthors int);

-- Publications --
DROP TABLE Prac3.dbo.publications;
CREATE TABLE Prac3.dbo.publications (ID int IDENTITY(1, 1) PRIMARY KEY WITH (IGNORE_DUP_KEY = ON),
	name varchar(255) UNIQUE,
	journal varchar(255),
	publ_year int);

-- Key words --
DROP TABLE Prac3.dbo.KW;
CREATE TABLE Prac3.dbo.KW (publ_ID int, word varchar(255));


DECLARE db_cursor CURSOR FOR
SELECT [Column 0], [Column 1], [Column 2], [Column 4], [Column 5], [Column 6]
FROM Prac3.dbo.SCI850;

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @all_authors, @publ, @publ_stat, @SC_stat, @KW1, @KW2;

WHILE @@FETCH_STATUS = 0
BEGIN
	-- JOURNAL --
	DECLARE cur CURSOR FOR
	SELECT * FROM Prac3.dbo.Split(@publ_stat, ',');
	
	OPEN cur
	FETCH NEXT FROM cur INTO @journal;
	
	SELECT @journal = LTRIM(@journal);

	SET @temp = @journal;
	SET @pos = PATINDEX('%[0-9]%', @journal);
	SET @journal_name = SUBSTRING(@journal, 1, @pos - 2);
	SET @journal = SUBSTRING(@journal, @pos, LEN(@journal));
	select @journal = left(@journal, patindex('%[^0-9]%', @journal + '.') - 1);
	SET @publ_year = CONVERT (int, @journal);
	
	CLOSE cur
	DEALLOCATE cur

	IF EXISTS (SELECT 1 FROM Prac3.dbo.publications WHERE name = @publ)
		SELECT @dup_ID = ID FROM Prac3.dbo.publications WHERE name = @publ;
	IF EXISTS (SELECT 1 FROM Prac3.dbo.publications WHERE name = @publ)
		PRINT 'Duplicate with ID = ' + CONVERT(varchar, @dup_ID);
	IF NOT EXISTS (SELECT 1 FROM Prac3.dbo.publications WHERE name = @publ)
		INSERT INTO Prac3.dbo.publications(name, journal, publ_year)
		VALUES (@publ, @journal_name, @publ_year);

	SELECT @publ_ID = ID FROM Prac3.dbo.publications WHERE name = @publ;

	IF NOT EXISTS (SELECT 1 FROM Prac3.dbo.journals WHERE name = @journal_name)
		INSERT INTO Prac3.dbo.journals(name)
		VALUES (@journal_name);
	SELECT @journal_ID = ID FROM Prac3.dbo.journals WHERE name = @journal_name;
	IF NOT EXISTS (SELECT 1 FROM Prac3.dbo.J_P
		WHERE journal_ID = @journal_ID AND publ_ID = @publ_ID)
		INSERT INTO Prac3.dbo.J_P(journal_ID, publ_ID)
		VALUES (@journal_ID, @publ_ID);

	-- Authors --
	DECLARE cur CURSOR FOR
	SELECT * FROM Prac3.dbo.Split(@all_authors, ' ');
	OPEN cur
	FETCH NEXT FROM cur INTO @author;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @author = UPPER(@author);
		IF NOT EXISTS (SELECT 1 FROM Prac3.dbo.authors WHERE name = @author)
			INSERT INTO Prac3.dbo.authors(name) VALUES (@author);
		SELECT @author_ID = ID FROM Prac3.dbo.authors WHERE name = @author;
		IF NOT EXISTS (SELECT 1 FROM Prac3.dbo.J_A WHERE author_ID = @author_ID)
			INSERT INTO Prac3.dbo.J_A(journal_ID, author_ID)
			VALUES (@journal_ID, @author_ID);
		
		INSERT INTO Prac3.dbo.A_P(author_ID, publ_ID)
			VALUES (@author_ID, @publ_ID);
		
		FETCH NEXT FROM cur INTO @author;
	END
	CLOSE cur
	DEALLOCATE cur

	-- SC --
	DECLARE cur CURSOR FOR
	SELECT * FROM Prac3.dbo.Split(@SC_stat, '/');
	OPEN cur
	FETCH NEXT FROM cur INTO @cur_SC;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE cur1 CURSOR FOR
		SELECT * FROM Prac3.dbo.Split(@cur_SC, ',');
		
		OPEN cur1
		FETCH NEXT FROM cur1 INTO @SC;
		SET @SC = UPPER(@SC);
		WHILE @@FETCH_STATUS = 0
		BEGIN
			FETCH NEXT FROM cur1 INTO @country;
		END
		SET @country = UPPER(@country);
		CLOSE cur1
		DEALLOCATE cur1

		IF NOT EXISTS (SELECT 1 FROM Prac3.dbo.SC WHERE SC = @SC)-- AND country = @country)
			INSERT INTO Prac3.dbo.SC(SC)--, country)
			VALUES (@SC);--, @country);

		SELECT @SC_ID = ID FROM Prac3.dbo.SC WHERE SC = @SC;-- AND country = @country;
		IF NOT EXISTS (SELECT 1 FROM Prac3.dbo.SC_P WHERE SC_ID = @SC_ID AND publ_ID = @publ_ID)
			INSERT INTO Prac3.dbo.SC_P(SC_ID, publ_ID)
			VALUES (@SC_ID, @publ_ID);
		
		FETCH NEXT FROM cur INTO @author;
	END

	CLOSE cur
	DEALLOCATE cur

	-- Key words --
	SET @KW1 = REPLACE(@KW1, '"', '');
	SET @KW2 = REPLACE(@KW2, '"', '');
	DECLARE cur CURSOR FOR
	SELECT * FROM Prac3.dbo.Split(@KW1 + @KW2, '; ');
	OPEN cur
	FETCH NEXT FROM cur INTO @KW;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @KW = RTRIM(LTRIM(UPPER(@KW)));
		IF NOT EXISTS (SELECT 1 FROM Prac3.dbo.KW WHERE publ_ID = @publ_ID AND word = @KW)
			INSERT INTO Prac3.dbo.KW(publ_ID, word)
			VALUES (@publ_ID, @KW);
		FETCH NEXT FROM cur INTO @KW;
	END
	CLOSE cur
	DEALLOCATE cur
	DECLARE cur CURSOR FOR
	SELECT * FROM Prac3.dbo.Split(@publ, ' ');
	OPEN cur
	FETCH NEXT FROM cur INTO @KW;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @KW = RTRIM(LTRIM(UPPER(@KW)));
		IF NOT EXISTS (SELECT 1 FROM Prac3.dbo.KW WHERE publ_ID = @publ_ID AND word = @KW)
			INSERT INTO Prac3.dbo.KW(publ_ID, word)
			VALUES (@publ_ID, @KW);
		FETCH NEXT FROM cur INTO @KW;
	END
	CLOSE cur
	DEALLOCATE cur

	FETCH NEXT FROM db_cursor INTO @all_authors, @publ, @publ_stat, @SC_stat, @KW1, @KW2;
END

CLOSE db_cursor   
DEALLOCATE db_cursor

-- Publications per journal count --
DECLARE db_cursor CURSOR FOR
	SELECT DISTINCT journal_ID
	FROM Prac3.dbo.J_P;
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @journal_ID;

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @cur = COUNT(*) FROM Prac3.dbo.J_P WHERE journal_ID = @journal_ID;
	INSERT INTO Prac3.dbo.J_P_count(journal_ID, npubl)
		VALUES (@journal_ID, @cur);
	FETCH NEXT FROM db_cursor INTO @journal_ID;
END

CLOSE db_cursor   
DEALLOCATE db_cursor

-- 5 last years --
SELECT @max_year = max(publ_year) FROM Prac3.dbo.publications;
DECLARE db_cursor CURSOR FOR
	SELECT journal_ID, publ_ID
	FROM Prac3.dbo.J_P;
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @journal_ID, @publ_ID;

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @cur = publ_year FROM Prac3.dbo.publications WHERE ID = @publ_ID;
	IF NOT EXISTS (SELECT 1 FROM Prac3.dbo.J_P_year WHERE journal_ID = @journal_ID)
		INSERT INTO Prac3.dbo.J_P_year(journal_ID, npubl, publ_year)
		VALUES (@journal_ID, 1, @cur)
	ELSE UPDATE Prac3.dbo.J_P_year
		SET npubl = npubl + 1
		WHERE journal_ID = @journal_ID AND publ_year = @cur;
	IF (@cur > @max_year - 5)
		IF NOT EXISTS (SELECT 1 FROM Prac3.dbo.J_P_count_5last WHERE journal_ID = @journal_ID)
			INSERT INTO Prac3.dbo.J_P_count_5last(journal_ID, npubl)
			VALUES (@journal_ID, 1)
		ELSE UPDATE Prac3.dbo.J_P_count_5last
			SET npubl = npubl + 1
			WHERE journal_ID = @journal_ID;
	FETCH NEXT FROM db_cursor INTO @journal_ID, @publ_ID;
END

CLOSE db_cursor   
DEALLOCATE db_cursor

-- Authors per journal count --
DECLARE db_cursor CURSOR FOR
	SELECT DISTINCT journal_ID
	FROM Prac3.dbo.J_A;
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @journal_ID;

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @cur = COUNT(*) FROM Prac3.dbo.J_A WHERE journal_ID = @journal_ID;
	INSERT INTO Prac3.dbo.J_A_count(journal_ID, nauthors)
		VALUES (@journal_ID, @cur);
	FETCH NEXT FROM db_cursor INTO @journal_ID;
END

CLOSE db_cursor   
DEALLOCATE db_cursor

INSERT INTO Prac3.dbo.J_A_count_name(journal_name, nauthors)
	SELECT name, nauthors
	FROM Prac3.dbo.journals j, Prac3.dbo.J_A_count a 
	WHERE j.ID = a.journal_ID;

INSERT INTO Prac3.dbo.J_P_count_name(journal_name, npubl)
	SELECT name, npubl
	FROM Prac3.dbo.journals j, Prac3.dbo.J_P_count p
	WHERE j.ID = p.journal_ID;

INSERT INTO Prac3.dbo.J_P_count_5last_name(journal_name, npubl)
	SELECT name, npubl
	FROM Prac3.dbo.journals j, Prac3.dbo.J_P_count_5last p
	WHERE j.ID = p.journal_ID;

Select * from Prac3.dbo.J_P_count_5last order by journal_ID