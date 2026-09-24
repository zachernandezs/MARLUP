
cd .

if "%1"=="" ("D:\Softwares\Matlab2026a\bin\win64\gmake"  -f PiL_MARLUP_IAC26.mk all) else ("D:\Softwares\Matlab2026a\bin\win64\gmake"  -f PiL_MARLUP_IAC26.mk %1)
@if errorlevel 1 goto error_exit

exit /B 0

:error_exit
echo The make command returned an error of %errorlevel%
exit /B 1