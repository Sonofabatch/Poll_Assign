@ECHO OFF

setlocal EnableDelayedExpansion

IF EXIST poll_report_WIP.txt DEL poll_report_WIP.txt

SET Today=%Date: =0%
SET Year=%Today:~-4%
SET Month=%Today:~-10,2%
SET Day=%Today:~-7,2%
SET DoW=%Today:~0,3%
SET CorrectDate=%Month%/%Day%/%Year%
SET /a prevPC=-1
ECHO    %CorrectDate%     STORES MISSED>>poll_report_WIP.txt
ECHO.>>poll_report_WIP.txt

IF %DoW%==Fri GOTO FridayFail
IF NOT EXIST %Year%-%Month%-%Day%_strnotpol.csv GOTO MiniPollMissing

:MiniPollCheck
FOR /F "skip=1 tokens=1 delims=&&" %%F IN (pollreport.txt) DO (
	SET _miniline=%%F
	FOR /F "tokens=1,2 delims= " %%G IN ("!_miniline!") DO (
		SET found=0
		FOR /F "skip=4 tokens=1 delims=," %%I IN (%Year%-%Month%-%Day%_strnotpol.csv) DO (
			:mpcreturn
			CALL :minioutput %%H %%I %%G
		)
		CALL :output2 %%G
	)
)
GOTO end


:output2
SET pcNum=%1
IF %found%==0 (
	IF !prevPC! LSS 0 SET /a prevPC=!pcNum!
	IF NOT !prevPC!==!pcNum! ECHO.>>poll_report_WIP.txt
	ECHO !_miniline!>>poll_report_WIP.txt
	SET found=1
	SET /a prevPC=!pcNum!
	GOTO :eof)
GOTO :eof

:minioutput
SET strNum=%1
SET /a strVal=%1
SET /a pcVal=%3
SET miniStore=%2
SET pcNum=%3
SET _minilineend=!_miniline:~9!
IF %strNum%==%miniStore% (
	SET found=1
	IF %strVal% LSS 10 (
		SET spaces=    
		ECHO.>NUL
	) ELSE (
		IF %strVal% LSS 100 (
			SET spaces=   
			ECHO.>NUL
		) ELSE ( 
			IF %strVal% LSS 1000 (
				SET spaces=  
				ECHO.>NUL
			) ELSE (
				SET spaces= 
				ECHO.>NUL
			)
		)
	)
	IF %pcVal% LSS 10 SET spaces= !spaces!
	SET _newminiline= !pcNum!!spaces!!strNum!*!_minilineend!
	IF !prevPC! LSS 0 SET /a prevPC=!pcNum!
	IF NOT !prevPC!==!pcNum! ECHO.>>poll_report_WIP.txt
	ECHO !_newminiline!>>poll_report_WIP.txt
	SET /a prevPC=!pcNum!
	GOTO mpcreturn
)
GOTO :eof

endlocal

:FridayFail
ECHO No mini-poll on Friday.
ECHO.
GOTO noMiniPoll

:MiniPollMissing
ECHO No Mini-poll sheet found and today is not Friday.
ECHO. 
ECHO 1. Continue
ECHO 2. Abort
CHOICE /C:12 /N /M "Enter Selection: "
IF errorlevel 2 goto end
IF errorlevel 1 goto noMiniPoll
GOTO end

:noMiniPoll
FOR /F "skip=1 tokens=1 delims=&&" %%F IN (pollreport.txt) DO (
	SET _miniline=%%F
	FOR /F "tokens=1,2 delims= " %%G IN ("!_miniline!") DO (
		SET found=0
		CALL :output2 %%G
	)
)
GOTO end

:end

