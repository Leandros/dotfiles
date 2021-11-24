@echo off

:: Initialize FNM
FOR /f "tokens=*" %%i IN ('fnm env --use-on-cd') DO CALL %%i
