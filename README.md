# EmbyVision - iPhone 原生杜比视界 & 原画质直出 Emby 客户端

> **专为追求极致音画质的 iPhone / iPad 用户打造的开源 Emby 播放器**  
> 突破 iOS 官方与常规网页端痛点，支持 **Dolby Vision（杜比视界 Profile 5 / 8.1 / 7 MEL）硬件级渲染** 与 **Direct Play（原画点对点直出，服务端零转码）**。

---

## 🌟 核心特性与技术亮点

1. **原生杜比视界（Native Dolby Vision）硬件直出**：
   - 采用 **KSPlayer + Apple VideoToolbox + AVSampleBufferDisplayLayer** 渲染管线。
   - 分离 MKV 封装中的 HEVC 视频与杜比视界 RPU（动态元数据），直接送入 iPhone 的 Super Retina XDR 屏幕硬件图层。
   - 完美展现高光与暗部层次，**彻底告别紫绿偏色和降级 SDR 泛灰**。
2. **强制原画质直出（Direct Play 零服务端转码）**：
   - 客户端深度定制 Emby 设备描述符，向服务端声明全格式解码能力（4K HEVC 10-bit、Atmos/TrueHD、DTS-HD、PGS/ASS 字幕等）。
   - 保证 Emby 服务端 CPU/GPU **0 占用**，100% 直出原始码流。
3. **沉浸式播放交互**：
   - 屏幕左侧上下滑动调节高动态亮度（支持 EDR 高光迸发）。
   - 屏幕右侧上下滑动调节音量，双击屏幕左右区域 ±10 秒快进快退。
   - 播放进度每 10 秒自动向 Emby 服务端精准心跳上报，多端无缝续播。
4. **一键多音轨与多字幕切换**：
   - 支持杜比全景声（Dolby Atmos）、DTS-HD MA、TrueHD 音轨切换。
   - 支持外挂 SRT/VTT 与内置高保真 ASS/PGS 蓝光图形字幕渲染。

---

## 🚀 Windows 用户：免 Mac 电脑 5 分钟云端打包 IPA 指南

本工程已完整配置 **GitHub Actions 自动化 CI/CD 编译打包工作流**，您无需购买 Mac 电脑，只需在 Windows 上几步操作即可直接生成 iPhone 安装包（`.ipa`）：

### 第一步：将工程推送到您的 GitHub 私有仓库
在当前工程目录 (`D:\Antigravity对话保存位置\EmbyVision_iOS`) 打开终端或 PowerShell 执行：

```bash
cd "D:\Antigravity对话保存位置\EmbyVision_iOS"

# 1. 初始化 Git
git init
git add .
git commit -m "feat: init EmbyVision native dolby vision player"

# 2. 关联您的 GitHub 仓库（若未创建请先在 github.com 创建一个新仓库，如 EmbyVision）
git remote add origin https://github.com/您的用户名/EmbyVision.git
git branch -M main
git push -u origin main
```

### 第二步：GitHub Actions 云端自动编译
1. 打开您的 GitHub 仓库页面，点击顶部的 **Actions** 标签。
2. 您会看到名为 `Build iOS IPA (EmbyVision)` 的自动化工作流正在运行。
3. 约 5-10 分钟后，macOS 云端机器编译完成，在构建详情页底部的 **Artifacts** 处，即可直接下载打包好的 **`EmbyVision-iOS-IPA.zip`**！
4. 解压后即可得到 **`EmbyVision.ipa`** 安装文件。

---

## 📱 iPhone 安装方法（三种方式任选其一）

### 方式一：Sideloadly 电脑自签安装（最推荐 Windows 用户，无门槛）
1. 在 Windows 电脑上下载安装 [Sideloadly 官网客户端](https://sideloadly.io/)。
2. 用数据线将 iPhone 连接到 Windows 电脑（手机上点击“信任此电脑”）。
3. 打开 Sideloadly，将下载的 `EmbyVision.ipa` 拖入软件窗口中。
4. 在 Apple ID 输入框中输入您的免费普通 Apple ID（用于给 App 签名，完全免费安全）。
5. 点击 **Start**，等待显示 `Done!` 即可装入手机。
6. 在 iPhone 手机上打开：`设置 -> 通用 -> VPN 与设备管理`，点击您的 Apple ID 并信任开发者证书即可打开使用！

### 方式二：TrollStore（巨魔商店 - 永久免越狱免重签）
- 若您的 iPhone 系统在 iOS 14.0 ~ 16.6.1 或 17.0，已安装 TrollStore：
  - 直接将 `EmbyVision.ipa` 隔空投送（AirDrop）或通过微信/网盘发送到 iPhone。
  - 用 TrollStore 打开并点击 **Install**，即可实现**永久有效、永不掉签**。

### 方式三：AltStore 自签
- 在 Windows 运行 AltServer，手机端通过 AltStore 无线自动续期安装。

---

## 🛠️ Mac 开发者本地调试（可选）

如果您手边有 Mac 电脑：
```bash
brew install xcodegen
xcodegen generate
open EmbyVision.xcodeproj
```
选择真机或模拟器即可直接运行调试。
