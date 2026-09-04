# OnyxVision（曜石视界）- 旗舰级 iOS 杜比全景声影音播放器

> **深度融合 Infuse 极致音画质与 VidHub 无界多源生态的终极自研播放器**  
> 突破苹果官方与常规播放器痛点，支持 **Dolby Vision（杜比视界 Profile 5 / 8.1 / 7 MEL）硬件级高光色调映射**、**AirPods 空间音频与全景声直出**、**Direct Play（强制原画直出，服务端零转码）** 与 **iCloud 多设备无缝续播**。

---

## 🌟 核心特性与技术亮点

1. **终极杜比视界（Native Dolby Vision）硬件直出**：
   - 采用 **Metal EDR + Apple VideoToolbox + KSPlayer** 现代着色器渲染管线；
   - 提取 MKV/MP4 容器中的 RPU 动态元数据，全额激发 iPhone Super Retina XDR 屏幕 1000~1600 nits 峰值亮度；
   - **彻底根治绿紫偏色与降级灰暗**，暗场深邃、高光夺目。
2. **强制原画质直出（Direct Play 0 服务端转码）**：
   - 向 Emby / Jellyfin 报备超级解码载荷，强行锁定原始码流传输；
   - 保证远程服务器 CPU/GPU **0 负荷占用**，4K 蓝光原盘毫秒级起播。
3. **空间音频与杜比全景声 (Dolby Atmos)**：
   - 针对 AirPods Pro / Max 深度适配影院级头部追踪空间音频；
   - 多声道音频硬件透传，内置人声对白智能增强（Speech Boost）算法。
4. **ASS/SSA 特效字幕渲染与 ±0.1s 极速微调**：
   - 本地毫秒级渲染炫酷双语特效字幕，支持字体位置调整与时间轴 ±0.1 秒步进微调。
5. **苹果官方 iCloud 多端无缝续播**：
   - 接入 Apple 原生 `NSUbiquitousKeyValueStore`，iPhone 看到一半，在同一 Apple ID 的 iPad 上自动秒速续播。
6. **全协议与国内网盘多源聚合**：
   - 直连 Emby、Jellyfin，同时原生支持通过 Alist 挂载百度网盘、阿里云盘、115网盘、夸克网盘与 WebDAV。

---

## 🚀 云端自动打包指南

本工程已完整配置 **GitHub Actions 自动化 CI/CD 云端构建工作流**：
1. 代码推送到 GitHub 后，云端 macOS 虚拟机将自动编译工程；
2. 构建完成后，前往仓库的 **Actions** 标签页即可一键下载 **`OnyxVision-iOS-IPA`** 安装包。

---

## 📱 iPhone 安装方法

### 方式一：Sideloadly 电脑自签安装（推荐，简单快速）
1. 用数据线将 iPhone 连接到电脑；
2. 打开电脑上的 **Sideloadly**；
3. 将解压得到的 **`OnyxVision.ipa`** 拖入 Sideloadly，输入您的 Apple ID，点击 **Start**；
4. 提示完成后，在手机上打开 `设置 -> 通用 -> VPN与设备管理`，点击信任您的证书即可！

### 方式二：TrollStore（巨魔商店 - 永久免签）
- 若您的 iPhone 处于支持 TrollStore 的版本，直接使用 AirDrop 发送 `OnyxVision.ipa` 到手机，使用 TrollStore 安装即可享受**永久免签、永不掉签**。
