@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  Сборка Notebook App под Windows (.exe)
rem  Запускать из каталога repository\win (рядом с папкой source\)
rem  Подробности и требования: BUILD_WINDOWS.md
rem ============================================================

cd /d "%~dp0source" || (
  echo [ОШИБКА] Не найден каталог "%~dp0source".
  exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ОШИБКА] Flutter не найден в PATH.
  echo Установите Flutter SDK: https://docs.flutter.dev/get-started/install/windows
  exit /b 1
)

echo === flutter doctor ===
call flutter doctor

echo === Включаем поддержку Windows ===
call flutter config --enable-windows-desktop

echo === Получаем зависимости ===
call flutter pub get || exit /b 1

echo === Сборка релиза (flutter build windows --release) ===
call flutter build windows --release || exit /b 1

rem --- Версия приложения из pubspec.yaml (строка "version: X.Y.Z+N") ---
set "APPVER=0.0.0"
for /f "tokens=2 delims=: " %%v in ('findstr /b /c:"version:" pubspec.yaml') do set "RAWVER=%%v"
for /f "tokens=1 delims=+" %%v in ("!RAWVER!") do set "APPVER=%%v"

set "SRCDIR=build\windows\x64\runner\Release"
if not exist "!SRCDIR!\notebook_app.exe" (
  echo [ОШИБКА] Не найден собранный файл "!SRCDIR!\notebook_app.exe".
  exit /b 1
)

set "OUTNAME=NotebookApp-!APPVER!-windows-x64"
set "OUTDIR=%~dp0!OUTNAME!"

if exist "!OUTDIR!" rmdir /s /q "!OUTDIR!"
mkdir "!OUTDIR!"
xcopy /e /i /y "!SRCDIR!\*" "!OUTDIR!\" >nul

echo === Упаковка в ZIP ===
powershell -NoProfile -Command "Compress-Archive -Path '!OUTDIR!\*' -DestinationPath '%~dp0!OUTNAME!.zip' -Force"

echo.
echo ============================================================
echo  Готово.
echo    Папка : !OUTDIR!
echo    Архив : %~dp0!OUTNAME!.zip
echo    Запуск: !OUTDIR!\notebook_app.exe
echo ============================================================
endlocal
