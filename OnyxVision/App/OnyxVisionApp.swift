import SwiftUI

@main
struct OnyxVisionApp: App {
    @StateObject private var env = AppEnvironment.shared
    @StateObject private var cloudSync = iCloudSyncManager.shared
    @StateObject private var multiSource = MultiSourceManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let server = env.currentServer {
                    LibraryHomeView(
                        server: server,
                        onLogout: {
                            env.logout()
                        }
                    )
                } else {
                    ServerLoginView(currentServer: $env.currentServer)
                }
            }
            .preferredColorScheme(.dark) // 曜石影音专属纯黑电影院模式，全额激发 OLED 杜比视界高对比度
        }
    }
}
