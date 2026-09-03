@echo off
chcp 65001 >nul
title EmbyVision iOS 一键推送到 GitHub 云端打包 IPA

echo ========================================================
echo       EmbyVision iOS 杜比视界播放器 - 云端打包助手
echo ========================================================
echo.
echo 本脚本将协助您将工程推送到您的 GitHub 仓库，触发 GitHub Actions 免费云端打包出 IPA！
echo.

set /p REPO_URL=请输入您的 GitHub 仓库地址 (例如 https://github.com/YourUsername/EmbyVision.git): 

if "%REPO_URL%"=="" (
    echo.
    echo [错误] 仓库地址不能为空！请重新运行脚本。
    pause
    exit /b 1
)

echo.
echo [*] 正在设置 Git 远程仓库...
git remote remove origin 2>nul
git remote add origin %REPO_URL%

echo [*] 正在推送到 GitHub 并创建 main 分支...
git branch -M main
git push -u origin main

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [!] 推送遇到问题，请检查：
    echo 1. 仓库地址是否正确？
    echo 2. 是否已在 GitHub 上创建该仓库？
    echo 3. 是否具备写入权限（若提示输入 Token，请使用 GitHub Personal Access Token 代替密码）。
) else (
    echo.
    echo ========================================================
    echo [成功] 代码已成功推送到 GitHub！
    echo.
    echo 请立即前往您的 GitHub 仓库页面:
    echo 1. 点击顶部的 [Actions] 标签页；
    echo 2. 可以看到 [Build iOS IPA (EmbyVision)] 正在自动编译；
    echo 3. 约 5-8 分钟编译完成后，在详情页底部的 [Artifacts] 下载 IPA 安装包！
    echo ========================================================
)

echo.
pause
