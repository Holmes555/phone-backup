@echo off
set EXTERNAL_DRIVE=R:\
set PHOTO_PHONE_DIR=/sdcard/DCIM/Camera
set DOWNLOAD_PHONE_DIR=/sdcard/Download

REM Check if the external drive is connected
echo [INFO] Checking if the external drive is connected...
if not exist "%EXTERNAL_DRIVE%" (
    echo [ERROR] External drive not found at %EXTERNAL_DRIVE%. Please connect it and try again.
    pause
    exit /b 1
)

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

REM Ask user for phone name
set /p PHONE_NAME="Enter your phone name: "

REM Create destination directories using phone name
set PHOTO_BACKUP_DIR=%EXTERNAL_DRIVE%\Destination\Photo\Dir\%PHONE_NAME%
set DOWNLOAD_BACKUP_DIR=%EXTERNAL_DRIVE%\Destination\Download\Dir\%PHONE_NAME%

echo ================================
echo  Choose folders to pull from phone
echo ================================
echo 1. Pull Photos (DCIM/Camera)
echo 2. Pull Downloads folder
echo 3. Pull Both Photos and Downloads
echo ================================
set /p choice="Enter your choice (1 for Photos, 2 for Downloads, Enter for both): "

for %%y in ("1", "") do (
    if %%y=="%choice%" (
        REM Ensure the photo backup directory exists
        mkdir "%PHOTO_BACKUP_DIR%" 2>nul
        
        REM List files in the source directory and pull them individually with progress indication
        echo [INFO] %DATE% %TIME% - Starting incremental backup for photos folder...
        echo [INFO] Pulling new files from phone...
        for /f "delims=" %%F in ('adb shell ls "%PHOTO_PHONE_DIR%"') do (
            REM Check if the file already exists locally and compare timestamps
            if exist "%PHOTO_BACKUP_DIR%\%%F" (
                REM Compare timestamps (you could also compare sizes or other attributes)
                for /f "delims=" %%T in ('adb shell stat -c %%s "%PHOTO_PHONE_DIR%/%%F"') do (
                    set PHONE_SIZE=%%T
                )
                for /f "delims=" %%T in ('dir "%PHOTO_BACKUP_DIR%\%%F" ^| findstr /i "%%F"') do (
                    set LOCAL_SIZE=%%T
                )
        
                REM If file sizes are different, pull the file
                if not "%PHONE_SIZE%"=="%LOCAL_SIZE%" (
                    echo [INFO] File %%F has been modified, pulling...
                    adb pull -a "%PHOTO_PHONE_DIR%/%%F" "%PHOTO_BACKUP_DIR%\%%F"
                ) else (
                    echo [INFO] File %%F is up to date.
                )
            ) else (
                REM If file doesn't exist, pull it
                echo [INFO] New file %%F, pulling...
                adb pull -a "%PHOTO_PHONE_DIR%/%%F" "%PHOTO_BACKUP_DIR%\%%F"
            )
        )
        
        if %ERRORLEVEL% NEQ 0 (
            echo [ERROR] %DATE% %TIME% - ADB pull failed! Check your phone connection.
            pause
            exit /b 1
        )
        
        echo [SUCCESS] %DATE% %TIME% - Backup photos complete! Files saved to: %PHOTO_BACKUP_DIR%
    )
)

for %%y in ("2", "") do (
    if %%y=="%choice%" (
        REM Ensure the download backup directory exists
        mkdir "%DOWNLOAD_BACKUP_DIR%" 2>nul
        
        REM List files in the source directory and pull them individually with progress indication
        echo [INFO] %DATE% %TIME% - Starting incremental backup for download folder...
        echo [INFO] Pulling new files from phone...
        for /f "delims=" %%F in ('adb shell ls "%DOWNLOAD_PHONE_DIR%"') do (
            REM Check if the file already exists locally and compare timestamps
            if exist "%DOWNLOAD_BACKUP_DIR%\%%F" (
                REM Compare timestamps (you could also compare sizes or other attributes)
                for /f "delims=" %%T in ('adb shell stat -c %%s "%DOWNLOAD_PHONE_DIR%/%%F"') do (
                    set PHONE_SIZE=%%T
                )
                for /f "delims=" %%T in ('dir "%DOWNLOAD_BACKUP_DIR%\%%F" ^| findstr /i "%%F"') do (
                    set LOCAL_SIZE=%%T
                )
        
                REM If file sizes are different, pull the file
                if not "%PHONE_SIZE%"=="%LOCAL_SIZE%" (
                    echo [INFO] File %%F has been modified, pulling...
                    adb pull -a "%DOWNLOAD_PHONE_DIR%/%%F" "%DOWNLOAD_BACKUP_DIR%\%%F"
                ) else (
                    echo [INFO] File %%F is up to date.
                )
            ) else (
                REM If file doesn't exist, pull it
                echo [INFO] New file %%F, pulling...
                adb pull -a "%DOWNLOAD_PHONE_DIR%/%%F" "%DOWNLOAD_BACKUP_DIR%\%%F"
            )
        )
        
        if %ERRORLEVEL% NEQ 0 (
            echo [ERROR] %DATE% %TIME% - ADB pull failed! Check your phone connection.
            pause
            exit /b 1
        )
        
        echo [SUCCESS] %DATE% %TIME% - Backup downloads complete! Files saved to: %DOWNLOADS_BACKUP_DIR%
    )
)

pause
exit /b 0
