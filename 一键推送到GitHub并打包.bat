@echo off
chcp 65001 >nul
title EmbyVision iOS 杜比视界播放器 - 一键推送到 GitHub 云端打包

echo ====================================================================
echo       EmbyVision iOS 杜比视界播放器 - GitHub 云端打包一键推送
echo ====================================================================
echo.
echo 目标仓库: https://github.com/Luofeng-Cloud/sqkd.git
echo 当前分支: main
echo.
echo [*] 正在推送代码至 GitHub (若弹出浏览器授权窗口，请点击 Authorize 确认)...
echo.

git push -u origin main

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ====================================================================
    echo [提示] 推送若提示鉴权失败，请检查：
    echo 1. 弹出的 GitHub 授权窗口是否已点击授权；
    echo 2. 若仓库已有其他初始文件(如 README/License)，可输入 y 强制覆盖推送：
    set /p FORCE_PUSH=是否强制覆盖推送到 main 分支？(y/n): 
    if /i "%FORCE_PUSH%"=="y" (
        git push -u origin main --force
    )
    echo ====================================================================
) else (
    echo.
    echo ====================================================================
    echo [成功] 全部代码已成功推送到您的 GitHub 仓库！
    echo.
    echo 自动化打包已在云端自动触发，请立即查看：
    echo 👉 https://github.com/Luofeng-Cloud/sqkd/actions
    echo.
    echo 约 5-8 分钟编译完成后，页面底部的 [Artifacts] 会生成 EmbyVision.ipa！
    echo ====================================================================
)

echo.
pause
