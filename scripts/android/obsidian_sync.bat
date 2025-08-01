@echo off
setlocal enabledelayedexpansion

set INTERNAL_DRIVE=D:\
set OBSIDIAN_SYNC_DIR=%INTERNAL_DRIVE%\Obsidian
set OBSIDIAN_PHONE_DIR=/sdcard/Documents/Obsidian

REM Check if the phone is connected and authorized
echo [INFO] Checking if the phone is connected...
set DEVICE_FOUND=0

for /f "tokens=1,2" %%A in ('adb devices') do (
    if "%%B"=="device" (
        set DEVICE_FOUND=1
        echo [INFO] Device detected: %%A
    ) 
    if "%%B"=="unauthorized" (
        echo [ERROR] Device detected: %%A, but it is unauthorized!
        echo [HINT] Please check your phone and allow USB debugging.
        pause
        exit /b 1
    )
)

if %DEVICE_FOUND%==0 (
    echo [ERROR] No authorized device detected! Make sure your phone is connected and USB debugging is enabled.
    pause
    exit /b 1
)

echo ================================
echo Initializing Obsidian sync...
echo ================================

REM Ensure the Obsidian sync directory exists
mkdir "%OBSIDIAN_SYNC_DIR%" 2>nul

REM List files in the source directory and pull them individually with progress indication
echo [INFO] %DATE% %TIME% - Starting incremental sync for Obsidian folder...
echo [INFO] Pulling new files from phone...
for /f "delims=" %%F in ('adb shell ls '%OBSIDIAN_PHONE_DIR%'') do (
    REM Check if the file already exists locally and compare timestamps
    if exist "%OBSIDIAN_SYNC_DIR%\%%F" (
        REM Compare timestamps (you could also compare sizes or other attributes)
        for /f "delims=" %%T in ('adb shell stat -c %%s '%OBSIDIAN_PHONE_DIR%/%%F'') do (
            set PHONE_SIZE=%%T
        )
        for %%L in ("%OBSIDIAN_SYNC_DIR%\%%F") do (
            set LOCAL_SIZE=%%~zL
        )

        REM If file sizes are different, pull the file
        if not "!PHONE_SIZE!"=="!LOCAL_SIZE!" (
            echo [INFO] File %%F has been modified, pulling...
            adb pull -a "%OBSIDIAN_PHONE_DIR%/%%F" "%OBSIDIAN_SYNC_DIR%\%%F"
        ) else (
            echo [INFO] File %%F is up to date.
        )
    ) else (
        REM If file doesn't exist, pull it
        echo [INFO] New file %%F, pulling...
        adb pull -a "%OBSIDIAN_PHONE_DIR%/%%F" "%OBSIDIAN_SYNC_DIR%\%%F"
    )
)

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] %DATE% %TIME% - ADB pull failed! Check your phone connection.
    pause
    exit /b 1
)

echo [SUCCESS] %DATE% %TIME% - Obsidian sync complete! Files saved to: %OBSIDIAN_SYNC_DIR%

pause
exit /b 0
