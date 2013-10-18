@ECHO OFF
setlocal EnableDelayedExpansion
SET RPTDIR="G:\mclist\DATA\CURRENT\"
SET SLSDIR="P:\Misc\bsnuggs\"
SET WRKDIR="C:\Users\rbeaman\Documents\Current Polling Reports\"
REM Testing values
REM	SET RPTDIR="H:\Portable Apps\Documents\CURRENT\"
REM	SET SLSDIR="H:\Portable Apps\Documents\list\"
REM	SET WRKDIR="H:\Portable Apps\Documents\WRKDIR\"
SET Today=%Date: =0%
SET Year=%Today:~-4%
SET Month=%Today:~-10,2%
SET Day=%Today:~-7,2%
SET CorrectDate=%Month%/%Day%/%Year%
SET DateCheckPassed=0
SET AppDir=%CD%
IF NOT EXIST %WRKDIR%%Year%%Month%%Day% MD %WRKDIR%%Year%%Month%%Day%
SET /a retryCount=0
IF %1.==. (SET var1=NULL) ELSE (SET var1=%1)


REM Debugging
REM ECHO Report directory is %RPTDIR%
REM ECHO Store List is located in %SLSDIR%
REM ECHO Working directory is %WRKDIR%
REM ECHO Today is %CorrectDate%
REM ECHO App directory is %AppDir%
REM ECHO Variable Parameter 1 is %var1%

IF EXIST %WRKDIR%%Year%%Month%%Day%\TOTALS.RPT GOTO SecondRun


:DateCheck
SET /a retryCount+=1
IF %retryCount% GTR 20 (
	ECHO Too many retries
	PAUSE
	GOTO end)
CD /D %RPTDIR%
IF NOT EXIST TOTALS.RPT GOTO noTOTRPT
FOR /F "tokens=1 delims= " %%A IN ('dir TOTALS.RPT') DO IF "%%A"=="%CorrectDate%" SET DateCheckPassed=1
IF %DateCheckPassed%==1 (
	GOTO ParseReports
)	ELSE GOTO CONTCHOICE
   

:ParseReports
ECHO Date is current. Parsing Reports.
IF EXIST %SLSDIR%storelist.txt (Copy %SLSDIR%storelist.txt %WRKDIR%storelist.txt) ELSE (GOTO noSTRLST)
IF EXIST DATETIME.RPT (Copy DATETIME.RPT %WRKDIR%DATETIME.RPT) ELSE (GOTO noDTRPT)
IF EXIST MISSING.RPT (
	Copy MISSING.RPT %WRKDIR%MISSING.RPT
	Copy MISSING.RPT %WRKDIR%%Year%%Month%%Day%\MISSING.RPT
) ELSE (GOTO noMISRPT)
IF EXIST STRDMISS.RPT (
	Copy STRDMISS.RPT %WRKDIR%STRDMISS.RPT
	Copy STRDMISS.RPT %WRKDIR%%Year%%Month%%Day%\STRDMISS.RPT
) ELSE (GOTO noDOSRPT)
IF EXIST STRWMISS.RPT (
	Copy STRWMISS.RPT %WRKDIR%STRWMISS.RPT
	Copy STRWMISS.RPT %WRKDIR%%Year%%Month%%Day%\STRWMISS.RPT
) ELSE (GOTO noWINRPT)
IF EXIST PCTICK.RPT Copy PCTICK.RPT %WRKDIR%%Year%%Month%%Day%\PCTICK.RPT
IF EXIST PCTSAL.RPT Copy PCTSAL.RPT %WRKDIR%%Year%%Month%%Day%\PCTSAL.RPT
Copy TOTALS.RPT %WRKDIR%%Year%%Month%%Day%\TOTALS.RPT
CD /D %WRKDIR%
IF EXIST pollreport.txt DEL pollreport.txt

REM For every store in STWMISS.RPT Find matching line in storelist.txt and copy 2nd token (PCNUM)
REM 	replace 1st token with PCNUM and sort
REM %%A = Store info
REM %%B = Store# from STRWMISS.RPT
REM %%C = Store# from storelist.txt
REM %%D = PC# from storelist.txt

:FindReplaceStoreNumber
CD /D %WRKDIR%
FOR /F "skip=2 tokens=1 delims=&&" %%A IN (STRWMISS.RPT) DO (
	SET _line=%%A
	SET _newline=!_line:*9=!
	FOR /F "tokens=1 delims= " %%B IN ("!_newline!") DO (
		SET strfound=0
		FOR /F "tokens=1,2" %%C IN (storelist.txt) DO IF %%B==%%C CALL :output %%D
		CALL :FoundCheck
	)
)
:Sort
SORT < output.txt >> tempsortedoutput.txt
DEL output.txt
FOR /F "tokens=1 delims=&&" %%E IN (tempsortedoutput.txt) DO (
	SET _sortline=%%E
	SET _newsortlinestart=!_sortline:~1,2!
	SET _newsortlineend=!_sortline:~4!
	SET "_newsortline=!_newsortlinestart!!_newsortlineend!"
	ECHO  !_newsortline!>> pollreportwin.txt
)
DEL tempsortedoutput.txt


:Count
FIND /V "  X     X" MISSING.RPT | FIND /C " M " > missing.txt
SET /p missed= < missing.txt
del missing.txt
ECHO There were %missed% stores missed.

:CreateReports
ECHO (%missed%)
TYPE STRDMISS.RPT > pollreport.txt
TYPE pollreportwin.txt >> pollreport.txt
DEL pollreportwin.txt
CALL minipoll.bat
IF %var1%==-s (
	ECHO Printing skipped as a result of user flag.
	GOTO SkipPrint
) ELSE (
	notepad.exe /p poll_report.txt
	ECHO Printing poll_report.txt) 
	ECHO.
	ECHO.
	CHOICE /C:YN /t 30 /d Y /M "Print Missing and Date&Time? "
	IF errorlevel 2 goto SkipPrint
	IF errorlevel 1 goto PrintExtras
GOTO end

:FoundCheck
IF %strfound%==0 CALL :output 77
GOTO :eof

:SkipPrint
ECHO.
ECHO Reports will not be printed.
PAUSE
GOTO End

:PrintExtras
write.exe /p DATETIME.RPT
ECHO Printing DATETIME.RPT
ping -n 2 127.0.0.1>nul
write.exe /p MISSING.RPT
ECHO Printing MISSING.RPT
ping -n 2 127.0.0.1>nul
CALL missingsort.bat
notepad.exe /p sortedmissing.txt
ECHO Printing sortedmissing.txt
PAUSE
GOTO End

:CONTCHOICE
ECHO The reports are not current.
ECHO. 
ECHO 1. Ignore and continue
ECHO 2. Retry (attempt %retrycount%)
ECHO 3. Abort
CHOICE /C:123 /N /t 60 /d 2 /M "Enter Selection: "
IF errorlevel 3 goto end
IF errorlevel 2 GOTO DateCheck
IF errorlevel 1 goto ParseReports
GOTO end

:output
IF %1 LSS 10 (
	ECHO 1%1 !_newline!>> output.txt
) ELSE (
	ECHO 2%1!_newline!>> output.txt)
SET strfound=1
GOTO :eof

:noDTRPT
ECHO DATETIME.RPT couldn't be found
PAUSE
GOTO End

:noDOSRPT
ECHO STRDMISS.RPT couldn't be found
PAUSE
GOTO End

:noMISRPT
ECHO MISSING.RPT couldn't be found
PAUSE
GOTO End

:noSTRLST
ECHO storelist.txt couldn't be found
PAUSE
GOTO End

:noTOTRPT
ECHO TOTALS.RPT couldn't be found
PAUSE
GOTO End

:noWINRPT
ECHO STRWMISS.RPT couldn't be found
PAUSE
GOTO End

:SecondRun
ECHO Reports seem to have already been generated for today.
ECHO. 
ECHO 1. Continue with existing reports
ECHO 2. Continue and replace reports
ECHO 3. Abort
CHOICE /C:123 /N "Enter Selection: "
IF errorlevel 3 goto end
IF errorlevel 2 GOTO DateCheck
IF errorlevel 1 goto FindReplaceStoreNumber
GOTO end

:End
CD /D %AppDir%
Copy poll_report.txt %WRKDIR%%Year%%Month%%Day%\poll_report.txt
endlocal