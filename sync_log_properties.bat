@echo off
setlocal

REM === Set source and destination directories ===
set A=D:\IUShare\LogProperties
set B=C:\IUShare\LogProperties

echo Sync A -> B
robocopy "%A%" "%B%" /E /XO

echo Sync B -> A
robocopy "%B%" "%A%" /E /XO

echo Sync Complete!
pause
