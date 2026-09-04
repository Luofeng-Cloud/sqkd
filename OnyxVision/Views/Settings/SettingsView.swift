import SwiftUI

public struct SettingsView: View {
    public let server: EmbyServer
    public let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var cloudSync = iCloudSyncManager.shared
    @ObservedObject private var multiSource = MultiSourceManager.shared
    
    @AppStorage("hardware_decode_enabled") private var hardwareDecodeEnabled = true
    @AppStorage("direct_play_enforced") private var directPlayEnforced = true
    @AppStorage("buffer_duration_seconds") private var bufferDurationSeconds = 30
    @AppStorage("spatial_audio_enabled") private var spatialAudioEnabled = true
    @AppStorage("speech_boost_enabled") private var speechBoostEnabled = true
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("当前媒体源信息")) {
                    HStack {
                        Text("当前媒体库")
                        Spacer()
                        Text(server.url)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    HStack {
                        Text("当前用户")
                        Spacer()
                        Text(server.username)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("网络协议")
                        Spacer()
                        Text(server.isHttps ? "HTTPS 安全直连" : "HTTP")
                            .foregroundColor(server.isHttps ? .green : .orange)
                    }
                }
                
                Section(header: Text("苹果官方 iCloud 云同步 (跨设备无缝续播)"), footer: Text("开启后，在 iPhone 上观看的进度、历史记录将自动通过您的 iCloud 账号无缝同步到 iPad 等其他苹果设备。")) {
                    Toggle("iCloud 观看进度多端同步", isOn: $cloudSync.syncEnabled)
                }
                
                Section(header: Text("多源媒体聚合 (Alist / WebDAV / 国内网盘)"), footer: Text("OnyxVision 原生支持通过 Alist 驱动协议挂载百度网盘、阿里云盘、115网盘、夸克网盘以及家庭群晖 NAS。")) {
                    ForEach(multiSource.sources) { src in
                        HStack {
                            Image(systemName: src.type.iconName)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(src.name)
                                    .font(.subheadline)
                                if let badge = src.type.supportedNetdisksBadge {
                                    Text(badge)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if src.isConnected {
                                Text("已连接")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section(header: Text("杜比视界与原画引擎设置"), footer: Text("强制原画直出向服务端声明支持全规格 4K HEVC、Dolby Vision Profile 5/8.1/7、杜比全景声，服务端 0 负荷转码。")) {
                    Toggle("Apple VideoToolbox 硬件解码", isOn: $hardwareDecodeEnabled)
                    Toggle("强制原画直出 (Direct Play 零转码)", isOn: $directPlayEnforced)
                    Toggle("AirPods 空间音频与全景声直出", isOn: $spatialAudioEnabled)
                    Toggle("电影对白人声智能增强 (Speech Boost)", isOn: $speechBoostEnabled)
                    
                    Picker("网络预缓冲时长", selection: $bufferDurationSeconds) {
                        Text("15 秒 (极速秒开)").tag(15)
                        Text("30 秒 (推荐平衡)").tag(30)
                        Text("60 秒 (超大缓冲防弱网)").tag(60)
                    }
                }
                
                Section(header: Text("关于 OnyxVision (曜石视界)")) {
                    HStack {
                        Text("应用名称")
                        Spacer()
                        Text("曜石视界 (OnyxVision)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("客户端版本")
                        Spacer()
                        Text("v2.0.0 (Flagship Edition)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("解码与渲染内核")
                        Spacer()
                        Text("Metal EDR / VideoToolbox / KSPlayer")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        dismiss()
                        onLogout()
                    }) {
                        HStack {
                            Spacer()
                            Text("退出当前账号")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("偏好设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
