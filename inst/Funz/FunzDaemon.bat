@echo off

SET MAIN=org.funz.calculator.Calculator

setLocal EnableDelayedExpansion
set BASEDIR=lib\
set LIB="
for /F %%a in ('dir /B "%BASEDIR%funz-core-*.jar"') do (
  set LIB=!LIB!;%BASEDIR%%%a
)
for /F %%a in ('dir /B "%BASEDIR%funz-calculator-*.jar"') do (
  set LIB=!LIB!;%BASEDIR%%%a
)
for /F %%a in ('dir /B "%BASEDIR%commons-lang-*.jar"') do (
  set LIB=!LIB!;%BASEDIR%%%a
)
for /F %%a in ('dir /B "%BASEDIR%commons-io-*.jar"') do (
  set LIB=!LIB!;%BASEDIR%%%a
)
for /F %%a in ('dir /B "%BASEDIR%commons-exec-*.jar"') do (
  set LIB=!LIB!;%BASEDIR%%%a
)
for /F %%a in ('dir /B "%BASEDIR%ftpserver-*.jar"') do (
  set LIB=!LIB!;%BASEDIR%%%a
)
for /F %%a in ('dir /B "%BASEDIR%ftplet-*.jar"') do (
  set LIB=!LIB!;%BASEDIR%%%a
)
for /F %%a in ('dir /B "%BASEDIR%mina-*.jar"') do (
  set LIB=!LIB!;%BASEDIR%%%a
)
for /F %%a in ('dir /B "%BASEDIR%sigar-*.jar"') do (
  set LIB=!LIB!;%BASEDIR%%%a
)
for /F %%a in ('dir /B "%BASEDIR%slf4j-*.jar"') do (
  set LIB=!LIB!;%BASEDIR%%%a
)
set LIB=!LIB!"

SET CALCULATOR=file:calculator.xml
hostname > %TEMP%\hostname.txt
FOR /F %%i in (%TEMP%\hostname.txt) do set HOSTN=%%i
IF EXIST calculator-%HOSTN%.xml (SET CALCULATOR=file:calculator-%HOSTN%.xml)

start java -Dapp.home=. -classpath %LIB% %MAIN% %CALCULATOR%
