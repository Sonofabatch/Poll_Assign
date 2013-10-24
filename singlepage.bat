@ECHO OFF
REM For testing recreation of .RPT files without excess blank page
IF EXIST MISSINGX.RPT DEL MISSINGX.RPT
TYPE MISSING.RPT >  MISSINGX.RPT