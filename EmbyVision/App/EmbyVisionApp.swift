import SwiftUI

@main
struct EmbyVisionApp: App {
    @StateObject private var env = AppEnvironment.shared
    
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
            .preferredColorScheme(.dark) // 影音专属纯黑电影院模式，保护 HDR 高动态对比度
        }
    }
}
