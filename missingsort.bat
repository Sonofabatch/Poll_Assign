@echo off

SET Today=%Date: =0%
SET Year=%Today:~-4%
SET Month=%Today:~-10,2%
SET Day=%Today:~-7,2%

IF EXIST sortedmissing.txt DEL sortedmissing.txt
setlocal EnableDelayedExpansion
FOR /F "skip=5 tokens=1 delims=&&" %%A IN (MISSING.RPT) DO (
	SET _sortline=%%A
	SET _newsortline=!_sortline:~1!
	ECHO  !_newsortline!>> missing.txt
)
FIND /V "/" missing.txt > tempmissing.txt
DEL missing.txt
SORT < tempmissing.txt >> sortedmissing.txt
DEL tempmissing.txt
endlocal



