sp_findtab vendor


USE redacted;
GO
ALTER DATABASE redacted
REMOVE FILE ;
GO 

ALTER TABLE redacted
ALTER COLUMN column1 numeric;

ALTER TABLE redacted
ADD column3 nvarchar(MAX);


ALTER TABLE redacted
ADD column4 nvarchar(MAX);

ALTER TABLE redacted
ADD column5 nvarchar(MAX);

ALTER TABLE redacted
ADD column6 nvarchar(MAX);

ALTER TABLE redacted
ADD column7 datetime;

ALTER TABLE redacted
ADD column8 nvarchar(MAX);

ALTER TABLE redacted
ADD column9 datetime;


ALTER TABLE redacted
ADD column10 nvarchar(MAX);

ALTER TABLE redacted
ADD column11 nvarchar(MAX);
