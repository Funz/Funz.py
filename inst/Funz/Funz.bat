@echo off

if %1 == -h ( 
  echo Usage: Funz.bat COMMAND [ARGS]
  echo
  echo   Run ...             Launch remote calculations, replacing variables by given values
  echo   Design ...          Apply an algorithm on an executable program returning target output value
  echo   RunDesign ...       Apply an algorithm and launch required calculations
  echo   ParseInput ...      Find variables inside parametrized input file
  echo   CompileInput ...    Replace variables inside parametrized input file
  echo   ReadOutput ...      Read output files content
  echo   GridStatus          Display calculators list and status
  exit /B 0
) else (
if %1 == --help ( 
  echo Usage: Funz.bat COMMAND [ARGS]
  echo 
  echo   Run ...             Launch remote calculations, replacing variables by given values
  echo   Design ...          Apply an algorithm on an executable program returning target output value
  echo   RunDesign ...       Apply an algorithm and launch required calculations
  echo   ParseInput ...      Find variables inside parametrized input file
  echo   CompileInput ...    Replace variables inside parametrized input file
  echo   ReadOutput ...      Read output files content
  echo   GridStatus          Display calculators list and status
  exit /B 0
))

set FUNZ_PATH=%~dp0

set MAIN=org.funz.main.%1%

setLocal EnableDelayedExpansion
set BASEDIR=%FUNZ_PATH%lib\
set LIB=
for /F "delims=" %%a in ('dir /B /S "!BASEDIR!*.jar"') do (
  set LIB=%%a;!LIB!
)

java -Dcharset=ISO-8859-1 -Xmx512m -Dapp.home=%FUNZ_PATH% -classpath !LIB! %MAIN% %*
rem -Douterr=.%1% 

if NOT %ERRORLEVEL% == 0 (
  echo "See log file %1%.log"
  echo "See help: Funz.bat %1% -h"
)

