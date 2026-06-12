@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "DEST=C:\src\SponzeyFileSharing"
set "FLUTTER_BIN=C:\src\flutter\bin\flutter.bat"
set "RUN_PUBGET=1"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
if not defined LOCALAPPDATA set "LOCALAPPDATA=%USERPROFILE%\AppData\Local"
set "PUB_CACHE=%LOCALAPPDATA%\Pub\Cache"
set "DART_PUB_CACHE=%PUB_CACHE%"
set "SRC=%SCRIPT_DIR%"
set "SHARED_SRC_Y=Y:\AtomSoft\Sponzey Family\Sponzey FileSharing"
set "SHARED_SRC_Z=Z:\AtomSoft\Sponzey Family\Sponzey FileSharing"
set "SHARED_SRC_UNC=\\Mac\WorkPlaces\AtomSoft\Sponzey Family\Sponzey FileSharing"

if /I "%~1"=="--no-pub-get" set "RUN_PUBGET=0"

if /I "%SRC%"=="%DEST%" (
  if exist "%SHARED_SRC_Y%\pubspec.yaml" (
    set "SRC=%SHARED_SRC_Y%"
  ) else if exist "%SHARED_SRC_Z%\pubspec.yaml" (
    set "SRC=%SHARED_SRC_Z%"
  ) else if exist "%SHARED_SRC_UNC%\pubspec.yaml" (
    set "SRC=%SHARED_SRC_UNC%"
  )
)

echo [sync] Source      : %SRC%
echo [sync] Destination : %DEST%
echo [sync] Pub Cache   : %PUB_CACHE%

if /I "%SRC%"=="%DEST%" (
  echo [sync] Source and destination are identical.
  echo [sync] Shared source was not detected. Check Parallels shared drive mapping.
  exit /b 1
)

if not exist "%SRC%\pubspec.yaml" (
  echo [sync] pubspec.yaml not found in source directory.
  echo [sync] Run this script from the shared project root.
  exit /b 1
)

if not exist "%DEST%" (
  echo [sync] Creating destination directory...
  mkdir "%DEST%"
  if errorlevel 1 (
    echo [sync] Failed to create destination directory.
    exit /b 1
  )
)

echo [sync] Mirroring project files...
robocopy "%SRC%" "%DEST%" /MIR ^
  /XD ".dart_tool" "build" ".git" ".idea" ".vscode" ^
      "windows\flutter\ephemeral" "linux\flutter\ephemeral" "macos\Flutter\ephemeral" ^
  /XF ".flutter-plugins" ".flutter-plugins-dependencies" ".DS_Store" ^
  /R:2 /W:1 /NFL /NDL /NJH /NJS /NP

set "ROBOCODE=%ERRORLEVEL%"
if %ROBOCODE% GEQ 8 (
  echo [sync] robocopy failed with exit code %ROBOCODE%.
  exit /b %ROBOCODE%
)

echo [sync] Sync complete. robocopy exit code %ROBOCODE%.
echo [sync] Cleaning generated Flutter files...
attrib -R "%DEST%\*" /S /D >nul 2>nul
if exist "%DEST%\.dart_tool" rmdir /s /q "%DEST%\.dart_tool"
if exist "%DEST%\.flutter-plugins" del /f /q "%DEST%\.flutter-plugins"
if exist "%DEST%\.flutter-plugins-dependencies" del /f /q "%DEST%\.flutter-plugins-dependencies"
if exist "%DEST%\windows\flutter\ephemeral" rmdir /s /q "%DEST%\windows\flutter\ephemeral"
if exist "%DEST%\linux\flutter\ephemeral" rmdir /s /q "%DEST%\linux\flutter\ephemeral"
if exist "%DEST%\macos\Flutter\ephemeral" rmdir /s /q "%DEST%\macos\Flutter\ephemeral"

if "%RUN_PUBGET%"=="1" if exist "%FLUTTER_BIN%" (
  echo [sync] Running flutter pub get...
  pushd "%DEST%"
  call "%FLUTTER_BIN%" pub get
  set "PUBGET_CODE=!ERRORLEVEL!"
  popd
  if not "!PUBGET_CODE!"=="0" (
    echo [sync] flutter pub get failed with exit code !PUBGET_CODE!.
    exit /b !PUBGET_CODE!
  )
  echo [sync] flutter pub get complete.
) else if "%RUN_PUBGET%"=="1" (
  echo [sync] Flutter not found at %FLUTTER_BIN%.
  echo [sync] Skipping flutter pub get.
)

echo [sync] Ready:
echo [sync]   cd /d %DEST%
if "%RUN_PUBGET%"=="0" echo [sync]   set PUB_CACHE=%PUB_CACHE%^&^& flutter pub get
echo [sync]   set PUB_CACHE=%PUB_CACHE%^&^& flutter run -d windows
exit /b 0
