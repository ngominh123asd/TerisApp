@echo off
title Run Teris Education App

REM === THÔNG TIN PHIÊN BẢN VÀ THỜI GIAN ===
set "CURRENT_VERSION=2"
set "START_DATE=2025-01-01"
set "END_DATE=2025-12-31"
set "GITHUB_USER=your-username"
set "GITHUB_REPO=your-repo-name"
set "UPDATE_URL=https://api.github.com/repos/%GITHUB_USER%/%GITHUB_REPO%/releases/latest"
set "INSTALL_PATH=C:\Program Files (x86)"

REM === KIỂM TRA CHẠY NGẦM HAY HIỂN THỊ ===
if "%1"=="hidden" goto HIDDEN_MODE
if "%1"=="update" goto UPDATE_MODE

REM === KIỂM TRA VÀ YÊU CẦU QUYỀN ADMIN ===
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( 
    goto gotAdmin 
)

:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
del "%temp%\getadmin.vbs"
exit /B

:gotAdmin
pushd "%CD%"
CD /D "%~dp0"

REM === SCRIPT CHÍNH - CHẾ ĐỘ HIỂN THỊ ===
color 0B
cls

set "FOLDER_NAME=Teris"
set "HIDDEN_NAME=Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
set "APP_PATH=Teris Viet Nam\Teris App\Teris-Education.exe"
set "APP_NAME=Teris-Education.exe"

echo =======================================
echo      RUN TERIS EDUCATION APP v%CURRENT_VERSION%
echo =======================================
echo Current directory: %CD%
echo.

REM === KIỂM TRA THỜI GIAN SỬ DỤNG ===
call :CHECK_DATE_VALIDITY
if %ERRORLEVEL% NEQ 0 goto DATE_EXPIRED

echo ✓ License valid until: %END_DATE%
echo.

REM === KIỂM TRA CẬP NHẬT TỰ ĐỘNG ===
echo Checking for updates...
call :CHECK_UPDATE
echo.

REM === KIỂM TRA TRẠNG THÁI THƒ MỤC ===
if EXIST "%HIDDEN_NAME%" goto CHECK_LOCKED
if NOT EXIST "%FOLDER_NAME%" goto FOLDER_NOT_FOUND

REM === THƒ MỤC ĐÃ MỞ KHÓA ===
:CHECK_UNLOCKED
echo Status: Folder is UNLOCKED
echo.
if EXIST "%FOLDER_NAME%\%APP_PATH%" (
    echo Starting Teris Education App...
    goto RUN_HIDDEN
) else (
    echo ✗ App not found at: %FOLDER_NAME%\%APP_PATH%
    echo Please check if the app is installed correctly.
    pause
)
goto END

REM === THƒ MỤC ĐÃ KHÓA ===
:CHECK_LOCKED
echo Status: Folder is LOCKED
echo.
echo ✓ Starting application...
goto RUN_HIDDEN

REM === CHẠY NGẦM HOÀN TOÀN ===
:RUN_HIDDEN
REM Lưu đường dẫn hiện tại vào file tạm
echo %CD% > "%temp%\teris_path.txt"

REM Tạo VBScript để chạy hoàn toàn ngầm
set "VBS_SCRIPT=%temp%\run_teris_hidden.vbs"
echo Set objShell = CreateObject("WScript.Shell") > "%VBS_SCRIPT%"
echo objShell.Run "cmd /c """"%~f0"""" hidden", 0, False >> "%VBS_SCRIPT%"

REM Chạy VBScript và thoát ngay
cscript //nologo "%VBS_SCRIPT%"
del "%VBS_SCRIPT%" >nul 2>&1
exit

REM === CHẾ ĐỘ NGẦM - KHÔNG HIỂN THỊ CỬA SỔ ===
:HIDDEN_MODE

REM Đọc đường dẫn từ file tạm
set /p WORK_DIR=<"%temp%\teris_path.txt"
del "%temp%\teris_path.txt" >nul 2>&1
cd /d "%WORK_DIR%"

set "FOLDER_NAME=Teris"
set "HIDDEN_NAME=Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
set "APP_PATH=Teris Viet Nam\Teris App\Teris-Education.exe"
set "APP_NAME=Teris-Education.exe"
set "MONITOR_SCRIPT=%temp%\teris_monitor_%RANDOM%.bat"

REM === TẠO THƒ MỤC TẠM THỜI HOÀN TOÀN ẨN ===
set "TEMP_FOLDER=%LOCALAPPDATA%\Microsoft\Windows\.NETFramework\%RANDOM%_%RANDOM%"
set "TEMP_APP_PATH=%TEMP_FOLDER%\%APP_PATH%"

REM === MỞ KHÓA VÀ SAO CHÉP VÀO THƒ MỤC TẠM ===
if EXIST "%HIDDEN_NAME%" (
    attrib -h -s "%HIDDEN_NAME%" >nul 2>&1
    ren "%HIDDEN_NAME%" "%FOLDER_NAME%" >nul 2>&1
    timeout /t 1 >nul
)

if EXIST "%FOLDER_NAME%\%APP_PATH%" (
    REM Tạo thư mục tạm thời với cấu trúc ẩn sâu
    md "%TEMP_FOLDER%\Teris Viet Nam\Teris App" >nul 2>&1
    
    REM Sao chép toàn bộ thư mục app vào temp
    xcopy "%FOLDER_NAME%\*" "%TEMP_FOLDER%\" /E /H /C /I /Q >nul 2>&1
    
    REM Đặt thuộc tính ẩn và hệ thống cho thư mục temp
    attrib +h +s "%TEMP_FOLDER%" >nul 2>&1
    
    REM Khóa lại thư mục gốc ngay lập tức
    ren "%FOLDER_NAME%" "%HIDDEN_NAME%" >nul 2>&1
    if %errorlevel% EQU 0 (
        attrib +h +s "%HIDDEN_NAME%" >nul 2>&1
    )
    
    REM Chạy ứng dụng từ thư mục tạm thời
    if EXIST "%TEMP_APP_PATH%" (
        start "" "%TEMP_APP_PATH%"
        
        REM Đợi app khởi động
        timeout /t 5 >nul
        
        REM Kiểm tra xem app đã chạy chưa
        tasklist /FI "IMAGENAME eq %APP_NAME%" 2>NUL | find /I "%APP_NAME%" >NUL
        if %ERRORLEVEL% EQU 0 (
            goto CREATE_TEMP_MONITOR
        ) else (
            timeout /t 5 >nul
            tasklist /FI "IMAGENAME eq %APP_NAME%" 2>NUL | find /I "%APP_NAME%" >NUL
            if %ERRORLEVEL% EQU 0 (
                goto CREATE_TEMP_MONITOR
            ) else (
                goto CLEANUP_TEMP
            )
        )
    ) else (
        goto CLEANUP_TEMP
    )
) else (
    exit
)

:CREATE_TEMP_MONITOR
REM === TẠO SCRIPT MONITOR VỚI DỌN DẸP THƒ MỤC TẠM ===
echo @echo off > "%MONITOR_SCRIPT%"
echo set "FOLDER_NAME=%FOLDER_NAME%" >> "%MONITOR_SCRIPT%"
echo set "HIDDEN_NAME=%HIDDEN_NAME%" >> "%MONITOR_SCRIPT%"
echo set "APP_NAME=%APP_NAME%" >> "%MONITOR_SCRIPT%"
echo set "WORK_DIR=%WORK_DIR%" >> "%MONITOR_SCRIPT%"
echo set "TEMP_FOLDER=%TEMP_FOLDER%" >> "%MONITOR_SCRIPT%"
echo cd /d "%%WORK_DIR%%" >> "%MONITOR_SCRIPT%"
echo :CHECK_LOOP >> "%MONITOR_SCRIPT%"
echo tasklist /FI "IMAGENAME eq %%APP_NAME%%" 2^>NUL ^| find /I "%%APP_NAME%%" ^>NUL >> "%MONITOR_SCRIPT%"
echo if %%ERRORLEVEL%% EQU 0 ( >> "%MONITOR_SCRIPT%"
echo     timeout /t 2 ^>nul >> "%MONITOR_SCRIPT%"
echo     goto CHECK_LOOP >> "%MONITOR_SCRIPT%"
echo ^) else ( >> "%MONITOR_SCRIPT%"
echo     goto CLEANUP_AND_EXIT >> "%MONITOR_SCRIPT%"
echo ^) >> "%MONITOR_SCRIPT%"
echo :CLEANUP_AND_EXIT >> "%MONITOR_SCRIPT%"
echo REM Đợi một chút để đảm bảo app đã đóng hoàn toàn >> "%MONITOR_SCRIPT%"
echo timeout /t 3 ^>nul >> "%MONITOR_SCRIPT%"
echo REM Xóa thư mục tạm thời hoàn toàn >> "%MONITOR_SCRIPT%"
echo attrib -h -s "%%TEMP_FOLDER%%" ^>nul 2^>^&1 >> "%MONITOR_SCRIPT%"
echo rd /s /q "%%TEMP_FOLDER%%" ^>nul 2^>^&1 >> "%MONITOR_SCRIPT%"
echo REM Thư mục gốc đã được khóa từ trước >> "%MONITOR_SCRIPT%"
echo del "%%~f0" ^>nul 2^>^&1 >> "%MONITOR_SCRIPT%"
echo exit >> "%MONITOR_SCRIPT%"

REM === TẠO VBS ĐỂ CHẠY MONITOR NGẦM ===
set "VBS_MONITOR=%temp%\monitor_teris_%RANDOM%.vbs"
echo Set objShell = CreateObject("WScript.Shell") > "%VBS_MONITOR%"
echo objShell.Run "cmd /c """"%MONITOR_SCRIPT%""""", 0, False >> "%VBS_MONITOR%"

REM Chạy monitor ngầm
cscript //nologo "%VBS_MONITOR%"
del "%VBS_MONITOR%" >nul 2>&1
exit

:CLEANUP_TEMP
REM Dọn dẹp thư mục tạm nếu app không chạy được
if EXIST "%TEMP_FOLDER%" (
    attrib -h -s "%TEMP_FOLDER%" >nul 2>&1
    rd /s /q "%TEMP_FOLDER%" >nul 2>&1
)
exit

REM === KIỂM TRA THỜI GIAN HỢP LỆ ===
:CHECK_DATE_VALIDITY
REM Sử dụng PowerShell để lấy ngày chính xác
for /f "delims=" %%i in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd'"') do set current_date=%%i


REM Chuyển đổi ngày thành số để so sánh chính xác
call :DATE_TO_DAYS "%current_date%" current_days
call :DATE_TO_DAYS "%START_DATE%" start_days  
call :DATE_TO_DAYS "%END_DATE%" end_days

if %current_days% LSS %start_days% exit /b 1
if %current_days% GTR %end_days% exit /b 1
exit /b 0

REM === CHUYỂN ĐỔI NGÀY THÀNH SỐ NGÀY ===
:DATE_TO_DAYS
setlocal
set date_str=%~1
for /f "tokens=1,2,3 delims=-" %%a in ("%date_str%") do (
    set yyyy=%%a
    set mm=%%b  
    set dd=%%c
)

REM Loại bỏ số 0 đầu để tránh lỗi octal
set /a mm=%mm%+0
set /a dd=%dd%+0
set /a yyyy=%yyyy%+0

REM Công thức tính số ngày từ năm 0 (xấp xỉ)
set /a days=%yyyy%*365+%yyyy%/4-%yyyy%/100+%yyyy%/400
set /a month_days=0

REM Cộng số ngày của các tháng trước
if %mm% GTR 1 set /a month_days=%month_days%+31
if %mm% GTR 2 set /a month_days=%month_days%+28
if %mm% GTR 3 set /a month_days=%month_days%+31  
if %mm% GTR 4 set /a month_days=%month_days%+30
if %mm% GTR 5 set /a month_days=%month_days%+31
if %mm% GTR 6 set /a month_days=%month_days%+30
if %mm% GTR 7 set /a month_days=%month_days%+31
if %mm% GTR 8 set /a month_days=%month_days%+31
if %mm% GTR 9 set /a month_days=%month_days%+30
if %mm% GTR 10 set /a month_days=%month_days%+31
if %mm% GTR 11 set /a month_days=%month_days%+30

REM Kiểm tra năm nhuận cho tháng 2
set /a leap_year=0
set /a temp=%yyyy%/4
set /a temp2=%temp%*4
if %temp2% EQU %yyyy% (
    set /a temp=%yyyy%/100
    set /a temp2=%temp%*100
    if %temp2% NEQ %yyyy% (
        set leap_year=1
    ) else (
        set /a temp=%yyyy%/400
        set /a temp2=%temp%*400
        if %temp2% EQU %yyyy% set leap_year=1
    )
)

if %mm% GTR 2 if %leap_year% EQU 1 set /a month_days=%month_days%+1

set /a total_days=%days%+%month_days%+%dd%
endlocal & set %~2=%total_days%
exit /b 0

REM === KIỂM TRA CẬP NHẬT TỪ GITHUB ===
:CHECK_UPDATE
set "TEMP_JSON=%temp%\github_release.json"
set "TEMP_BATCH=%temp%\download_update.bat"

REM Tạo script PowerShell để tải thông tin release
set "PS_SCRIPT=%temp%\check_github.ps1"
echo try { > "%PS_SCRIPT%"
echo     $response = Invoke-RestMethod -Uri "%UPDATE_URL%" -TimeoutSec 10 >> "%PS_SCRIPT%"
echo     $latestTag = $response.tag_name -replace 'v', '' >> "%PS_SCRIPT%"
echo     Write-Host $latestTag >> "%PS_SCRIPT%"
echo     if ([int]$latestTag -gt %CURRENT_VERSION%) { >> "%PS_SCRIPT%"
echo         $downloadUrl = $response.assets ^| Where-Object {$_.name -like "run_pt-v*.bat"} ^| Select-Object -First 1 -ExpandProperty browser_download_url >> "%PS_SCRIPT%"
echo         Write-Host "UPDATE_AVAILABLE" >> "%PS_SCRIPT%"
echo         Write-Host $downloadUrl >> "%PS_SCRIPT%"
echo     } else { >> "%PS_SCRIPT%"
echo         Write-Host "UP_TO_DATE" >> "%PS_SCRIPT%"
echo     } >> "%PS_SCRIPT%"
echo } catch { >> "%PS_SCRIPT%"
echo     Write-Host "CHECK_FAILED" >> "%PS_SCRIPT%"
echo } >> "%PS_SCRIPT%"

REM Chạy PowerShell script
for /f "delims=" %%i in ('powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%"') do (
    if "%%i"=="UPDATE_AVAILABLE" (
        set "UPDATE_STATUS=UPDATE_AVAILABLE"
    ) else if "%%i"=="UP_TO_DATE" (
        set "UPDATE_STATUS=UP_TO_DATE"
    ) else if "%%i"=="CHECK_FAILED" (
        set "UPDATE_STATUS=CHECK_FAILED"
    ) else if defined UPDATE_STATUS (
        if "!UPDATE_STATUS!"=="UPDATE_AVAILABLE" (
            set "DOWNLOAD_URL=%%i"
        ) else (
            set "LATEST_VERSION=%%i"
        )
    )
)

del "%PS_SCRIPT%" >nul 2>&1

if "%UPDATE_STATUS%"=="UPDATE_AVAILABLE" (
    echo ⚠ New version available! Downloading update...
    call :DOWNLOAD_UPDATE
) else if "%UPDATE_STATUS%"=="UP_TO_DATE" (
    echo ✓ You have the latest version
) else (
    echo ⚠ Unable to check for updates ^(continuing with current version^)
)
exit /b 0

REM === TẢI VÀ CÀI ĐẶT CẬP NHẬT ===
:DOWNLOAD_UPDATE
set "TEMP_UPDATE=%temp%\run_pt-v%LATEST_VERSION%.bat"
set "CURRENT_FILE=%~f0"

REM Tạo script PowerShell để tải file
set "DL_SCRIPT=%temp%\download_file.ps1"
echo try { > "%DL_SCRIPT%"
echo     Invoke-WebRequest -Uri "%DOWNLOAD_URL%" -OutFile "%TEMP_UPDATE%" -TimeoutSec 30 >> "%DL_SCRIPT%"
echo     Write-Host "DOWNLOAD_SUCCESS" >> "%DL_SCRIPT%"
echo } catch { >> "%DL_SCRIPT%"
echo     Write-Host "DOWNLOAD_FAILED" >> "%DL_SCRIPT%"
echo } >> "%DL_SCRIPT%"

for /f "delims=" %%i in ('powershell -ExecutionPolicy Bypass -File "%DL_SCRIPT%"') do (
    set "DOWNLOAD_RESULT=%%i"
)

del "%DL_SCRIPT%" >nul 2>&1

if "%DOWNLOAD_RESULT%"=="DOWNLOAD_SUCCESS" (
    echo ✓ Update downloaded successfully!
    echo Installing update to Program Files ^(x86^)...
    
    REM Tạo script cập nhật để chạy với quyền admin
    set "UPDATE_SCRIPT=%temp%\install_update.bat"
    echo @echo off > "%UPDATE_SCRIPT%"
    echo timeout /t 2 ^>nul >> "%UPDATE_SCRIPT%"
    echo copy "%TEMP_UPDATE%" "%INSTALL_PATH%\run_pt-v%LATEST_VERSION%.bat" ^>nul 2^>^&1 >> "%UPDATE_SCRIPT%"
    echo if exist "%INSTALL_PATH%\run_pt-v%LATEST_VERSION%.bat" ( >> "%UPDATE_SCRIPT%"
    echo     echo ✓ Update installed successfully! >> "%UPDATE_SCRIPT%"
    echo     echo Starting new version... >> "%UPDATE_SCRIPT%"
    echo     start "" "%INSTALL_PATH%\run_pt-v%LATEST_VERSION%.bat" >> "%UPDATE_SCRIPT%"
    echo ^) else ( >> "%UPDATE_SCRIPT%"
    echo     echo ✗ Failed to install update. Starting current version... >> "%UPDATE_SCRIPT%"
    echo     start "" "%CURRENT_FILE%" >> "%UPDATE_SCRIPT%"
    echo ^) >> "%UPDATE_SCRIPT%"
    echo del "%TEMP_UPDATE%" ^>nul 2^>^&1 >> "%UPDATE_SCRIPT%"
    echo del "%%~f0" ^>nul 2^>^&1 >> "%UPDATE_SCRIPT%"
    echo exit >> "%UPDATE_SCRIPT%"
    
    REM Chạy script cập nhật với quyền admin
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%UPDATE_SCRIPT%\"' -Verb RunAs" >nul 2>&1
    
    echo Update process initiated. This window will close...
    timeout /t 3 >nul
    exit
) else (
    echo ✗ Failed to download update. Continuing with current version...
    timeout /t 2 >nul
)
exit /b 0

REM === HẾT HẠN SỬ DỤNG ===
:DATE_EXPIRED
echo =======================================
echo        LICENSE EXPIRED
echo =======================================
echo.
echo ✗ This application license has expired.
echo Valid period: %START_DATE% to %END_DATE%
echo.
echo Please contact administrator for license renewal.
pause
goto END

REM === KHÔNG TÌM THẤY THƒ MỤC ===
:FOLDER_NOT_FOUND
echo ✗ Error: Teris folder not found!
echo Please run the Folder Protection script first to create the folder.
pause
goto END

:END
exit