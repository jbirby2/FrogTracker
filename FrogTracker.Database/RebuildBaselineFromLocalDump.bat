
set BatchFileDirectory=%CD%

cd "C:\Program Files\MySQL\MySQL Server 8.0\bin"

mysqldump -uFrogTracker -p53c9eec9-b7ae-49cd-9f99-c7af4a0c12e9 --routines --single-transaction --no-data --databases frogtracker --result-file="%BatchFileDirectory%\frogtracker-baseline.sql"
