@echo off
setlocal enabledelayedexpansion

:: Set console colors for better readability
color 0A

:: Set title
title V2Ray Proxy Manager

:: Initialize variables
set "PROXY_PORT=1080"
set "CONTAINER_NAME=v2ray-client"
set "COMPOSE_FILE=docker-compose.yml"
set "ENV_FILE=.env.local"
set "MAX_RETRIES=3"
set "RETRY_COUNT=0"

:: Function to print colored text
:printColor
if "%~1"=="success" (
    echo [92m%~2[0m
) else if "%~1"=="error" (
    echo [91m%~2[0m
) else if "%~1"=="warning" (
    echo [93m%~2[0m
) else if "%~1"=="info" (
    echo [94m%~2[0m
) else (
    echo %~1
)
goto :eof

:: Function to check if Docker is running
:checkDocker
call :printColor "info" "Checking if Docker is running..."
docker version >nul 2>&1
if %errorlevel% neq 0 (
    call :printColor "error" "Docker is not running or not installed!"
    call :printColor "warning" "Please start Docker Desktop and try again."
    pause
    exit /b 1
)
call :printColor "success" "Docker is running."
goto :eof

:: Function to check if proxy is already running
:checkProxyStatus
call :printColor "info" "Checking proxy status on port %PROXY_PORT%..."
netstat -an | findstr ":%PROXY_PORT% " >nul 2>&1
if %errorlevel% equ 0 (
    call :printColor "success" "Proxy is already running on port %PROXY_PORT%."
    
    :: Check if it's our container
    docker ps --filter "name=%CONTAINER_NAME%" --format "table {{.Names}}\t{{.Status}}" | findstr "%CONTAINER_NAME%" >nul 2>&1
    if %errorlevel% equ 0 (
        call :printColor "success" "V2Ray container is running."
        docker ps --filter "name=%CONTAINER_NAME%" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        set "PROXY_RUNNING=true"
    ) else (
        call :printColor "warning" "Port %PROXY_PORT% is in use but not by our container."
        set "PROXY_RUNNING=false"
    )
) else (
    call :printColor "info" "Proxy is not running on port %PROXY_PORT%."
    set "PROXY_RUNNING=false"
)
goto :eof

:: Function to start the proxy
:startProxy
if "%PROXY_RUNNING%"=="true" (
    call :printColor "warning" "Proxy is already running!"
    goto :menu
)

call :printColor "info" "Starting V2Ray proxy..."

:: Check if required files exist
if not exist "%COMPOSE_FILE%" (
    call :printColor "error" "Docker Compose file not found: %COMPOSE_FILE%"
    pause
    goto :menu
)

if not exist "%ENV_FILE%" (
    call :printColor "error" "Environment file not found: %ENV_FILE%"
    pause
    goto :menu
)

:: Start the containers
:retryStart
set /a RETRY_COUNT+=1
call :printColor "info" "Attempt %RETRY_COUNT% of %MAX_RETRIES%..."

docker-compose --env-file "%ENV_FILE%" up -d
if %errorlevel% neq 0 (
    if %RETRY_COUNT% lss %MAX_RETRIES% (
        call :printColor "warning" "Start failed, retrying in 3 seconds..."
        timeout /t 3 /nobreak >nul
        goto retryStart
    ) else (
        call :printColor "error" "Failed to start proxy after %MAX_RETRIES% attempts."
        call :printColor "info" "Please check the Docker logs for more information."
        pause
        goto :menu
    )
)

:: Wait a moment for the container to start
timeout /t 5 /nobreak >nul

:: Check if proxy started successfully
call :checkProxyStatus
if "%PROXY_RUNNING%"=="true" (
    call :printColor "success" "V2Ray proxy started successfully!"
    call :printColor "info" "Proxy is listening on 127.0.0.1:%PROXY_PORT%"
    call :printColor "info" "Configure your applications to use SOCKS5 proxy: 127.0.0.1:%PROXY_PORT%"
) else (
    call :printColor "error" "Proxy failed to start properly."
    call :printColor "info" "Checking container logs..."
    docker logs %CONTAINER_NAME%
)
goto :menu

:: Function to stop the proxy
:stopProxy
call :printColor "info" "Checking proxy status..."
call :checkProxyStatus

if "%PROXY_RUNNING%"=="false" (
    call :printColor "warning" "Proxy is not running."
    goto :menu
)

call :printColor "warning" "WARNING: Stopping the proxy will disconnect all applications using it!"
call :printColor "info" "Make sure no important applications are connected."
set /p "confirm=Are you sure you want to stop the proxy? (y/N): "
if /i not "%confirm%"=="y" (
    call :printColor "info" "Operation cancelled."
    goto :menu
)

call :printColor "info" "Stopping V2Ray proxy..."
docker-compose down
if %errorlevel% equ 0 (
    call :printColor "success" "Proxy stopped successfully."
) else (
    call :printColor "error" "Failed to stop proxy."
)
goto :menu

:: Function to show detailed status
:showStatus
call :printColor "info" "=== V2Ray Proxy Status ==="
call :checkProxyStatus

call :printColor "info" ""
call :printColor "info" "=== Docker Container Status ==="
docker ps --filter "name=%CONTAINER_NAME%" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"

call :printColor "info" ""
call :printColor "info" "=== Port Information ==="
netstat -an | findstr ":%PROXY_PORT% "

call :printColor "info" ""
call :printColor "info" "=== Recent Container Logs ==="
docker logs --tail 10 %CONTAINER_NAME% 2>nul
if %errorlevel% neq 0 (
    call :printColor "warning" "No logs available (container may not be running)."
)

call :printColor "info" ""
call :printColor "info" "=== Configuration Summary ==="
call :printColor "info" "Proxy Port: %PROXY_PORT%"
call :printColor "info" "Container Name: %CONTAINER_NAME%"
call :printColor "info" "Environment File: %ENV_FILE%"
call :printColor "info" "Compose File: %COMPOSE_FILE%"

pause
goto :menu

:: Function to show help
:showHelp
cls
call :printColor "info" "=== V2Ray Proxy Manager Help ==="
call :printColor "info" ""
call :printColor "info" "This script helps you manage your V2Ray proxy service."
call :printColor "info" ""
call :printColor "info" "Available Options:"
call :printColor "info" "1. Start Proxy - Starts the V2Ray proxy service"
call :printColor "info" "2. Stop Proxy - Stops the V2Ray proxy service"
call :printColor "info" "3. Check Status - Shows detailed proxy status"
call :printColor "info" "4. View Logs - Shows recent container logs"
call :printColor "info" "5. Restart Proxy - Stops and starts the proxy"
call :printColor "info" "6. Help - Shows this help message"
call :printColor "info" "0. Exit - Closes this application"
call :printColor "info" ""
call :printColor "info" "Proxy Configuration:"
call :printColor "info" "- SOCKS5 Proxy: 127.0.0.1:%PROXY_PORT%"
call :printColor "info" "- Container: %CONTAINER_NAME%"
call :printColor "info" ""
call :printColor "info" "Troubleshooting:"
call :printColor "warning" "- If proxy fails to start, check if Docker is running"
call :printColor "warning" "- Make sure port %PROXY_PORT% is not used by other applications"
call :printColor "warning" "- Check Docker logs for detailed error messages"
call :printColor "info" ""
call :printColor "info" "For more help, check the project documentation."
pause
goto :menu

:: Function to view logs
:viewLogs
call :printColor "info" "=== Recent Container Logs ==="
docker logs --tail 20 %CONTAINER_NAME% 2>nul
if %errorlevel% neq 0 (
    call :printColor "warning" "No logs available. Container may not be running."
    call :printColor "info" "Try starting the proxy first."
)
pause
goto :menu

:: Function to restart proxy
:restartProxy
call :printColor "info" "Restarting V2Ray proxy..."
call :stopProxy
timeout /t 2 /nobreak >nul
call :startProxy
goto :menu

:: Main menu
:menu
cls
echo.
call :printColor "success" "=================================="
call :printColor "success" "    V2Ray Proxy Manager"
call :printColor "success" "=================================="
echo.
call :printColor "info" "Current Status:"
call :checkProxyStatus
echo.
call :printColor "info" "Please select an option:"
echo.
call :printColor "info" "1. Start Proxy"
call :printColor "info" "2. Stop Proxy"
call :printColor "info" "3. Check Status"
call :printColor "info" "4. View Logs"
call :printColor "info" "5. Restart Proxy"
call :printColor "info" "6. Help"
call :printColor "info" "0. Exit"
echo.
set /p "choice=Enter your choice (0-6): "

if "%choice%"=="1" goto startProxy
if "%choice%"=="2" goto stopProxy
if "%choice%"=="3" goto showStatus
if "%choice%"=="4" goto viewLogs
if "%choice%"=="5" goto restartProxy
if "%choice%"=="6" goto showHelp
if "%choice%"=="0" goto exit

call :printColor "error" "Invalid choice. Please try again."
pause
goto :menu

:exit
call :printColor "info" "Thank you for using V2Ray Proxy Manager!"
call :printColor "info" "Goodbye!"
timeout /t 2 /nobreak >nul
exit /b 0

:: Main execution starts here
:main
:: Check if Docker is available
call :checkDocker
if %errorlevel% neq 0 (
    exit /b 1
)

:: Show welcome message
cls
call :printColor "success" "=================================="
call :printColor "success" "    V2Ray Proxy Manager"
call :printColor "success" "=================================="
call :printColor "info" ""
call :printColor "info" "Welcome to the V2Ray Proxy Manager!"
call :printColor "info" "This tool helps you easily manage your V2Ray proxy service."
call :printColor "info" ""
call :printColor "info" "Features:"
call :printColor "info" "- Easy start/stop with one click"
call :printColor "info" "- Automatic status monitoring"
call :printColor "info" "- Error handling and retry logic"
call :printColor "info" "- Detailed logging and diagnostics"
call :printColor "info" ""
call :printColor "info" "Press any key to continue..."
pause >nul

:: Go to main menu
goto :menu