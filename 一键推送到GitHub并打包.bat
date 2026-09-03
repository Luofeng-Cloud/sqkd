@echo off
title EmbyVision - Git Push to GitHub
cd /d D:\EmbyVision

echo ====================================================================
echo      EmbyVision iOS - Pushing code to GitHub Actions
echo      Repository: https://github.com/Luofeng-Cloud/sqkd.git
echo ====================================================================
echo.
echo [*] Pushing commits to GitHub...
echo [*] Note: If your browser opens a GitHub authorization window,
echo     please click the green [Authorize] button.
echo.

git push origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ====================================================================
    echo [SUCCESS] Code pushed successfully!
    echo Cloud build started on GitHub Actions.
    echo Opening browser to check build progress...
    echo ====================================================================
    start https://github.com/Luofeng-Cloud/sqkd/actions
) else (
    echo.
    echo ====================================================================
    echo [ERROR] Git push encountered an issue.
    echo Please make sure GitHub authorization is granted.
    echo ====================================================================
)

echo.
echo Press any key to exit this window...
pause >nul
