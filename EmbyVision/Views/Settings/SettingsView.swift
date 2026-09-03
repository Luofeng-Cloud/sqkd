import SwiftUI

public struct SettingsView: View {
    public let server: EmbyServer
    public let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("hardware_decode_enabled") private var hardwareDecodeEnabled = true
    @AppStorage("direct_play_enforced") private var directPlayEnforced = true
    @AppStorage("buffer_duration_seconds") private var bufferDurationSeconds = 30
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("当前服务器信息")) {
                    HStack {
                        Text("服务器地址")
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
                        Text("连接协议")
                        Spacer()
                        Text(server.isHttps ? "HTTPS 安全加密" : "HTTP")
                            .foregroundColor(server.isHttps ? .green : .orange)
                    }
                }
                
                Section(header: Text("杜比视界与原画引擎设置"), footer: Text("强制原画直出将向 Emby 声明支持完整 4K HEVC、杜比视界元数据及全景声音轨，杜绝服务端转码。硬件解码使用 Apple VideoToolbox 直接驱动 iPhone Super Retina XDR 屏幕呈现高光。")) {
                    Toggle("Apple VideoToolbox 硬件解码", isOn: $hardwareDecodeEnabled)
                    Toggle("强制原画直出 (Direct Play 零转码)", isOn: $directPlayEnforced)
                    
                    Picker("网络预缓冲时长", selection: $bufferDurationSeconds) {
                        Text("15 秒 (极速起播)").tag(15)
                        Text("30 秒 (推荐)").tag(30)
                        Text("60 秒 (超大缓冲防卡顿)").tag(60)
                    }
                }
                
                Section(header: Text("关于 EmbyVision")) {
                    HStack {
                        Text("客户端版本")
                        Spacer()
                        Text("v1.0.0 (Native Dolby Vision)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("渲染内核")
                        Spacer()
                        Text("KSPlayer / Metal EDR")
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
                            Text("退出当前 Emby 账号")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("设置与偏好")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
