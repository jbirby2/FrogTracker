
set BatchFileDirectory=%CD%

cd "C:\Program Files\MySQL\MySQL Server 8.0\bin"

mysqldump -uFrogTracker -p53c9eec9-b7ae-49cd-9f99-c7af4a0c12e9 --routines --single-transaction --databases frogtracker --result-file="%BatchFileDirectory%\frogtracker-mysql-dump.sql"

cd "%BatchFileDirectory%"

tar.exe -a -c -f frogtracker-mysql-dump.zip frogtracker-mysql-dump.sql

copy frogtracker-mysql-dump.zip C:\inetpub\wwwroot\FrogTracker\wwwroot\frogtracker-mysql-dump.zip

