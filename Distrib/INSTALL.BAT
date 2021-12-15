@echo off
cls
break on
if not exist tetris.EXE goto logdrive
if not exist figures.dat goto logdrive
if not exist records.dat goto logdrive
if #%1# == ## goto help

MkDir %1
Copy tetris.exe %1
copy figures.dat %1
copy records.dat %1
echo.
echo Установка завершена.
echo.
goto end

:help
echo Ошибка: Отсутствует обязательный параметр.
echo.
echo Параметр командной строки:
echo INSTALL  [Game dir]
echo.
echo где [Game dir] - имя директории в которую будет установлена игра.
echo.
echo Пример:
echo INSTALL  C:\GAMES\TETRIS
echo.
goto end

:logdrive
echo Ошибка:  Отсутствуют инсталляционные файлы.
echo.
goto end

:end
