import SwiftUI

public class AppEnvironment: ObservableObject {
    public static let shared = AppEnvironment()
    
    @Published public var currentServer: EmbyServer?
    
    private init() {
        restoreSession()
    }
    
    public func restoreSession() {
        if UserDefaults.standard.bool(forKey: "saved_remember"),
           let url = UserDefaults.standard.string(forKey: "saved_server_url"),
           let username = UserDefaults.standard.string(forKey: "saved_username"),
           let token = UserDefaults.standard.string(forKey: "saved_token"),
           let userId = UserDefaults.standard.string(forKey: "saved_user_id") {
            self.currentServer = EmbyServer(
                url: url,
                name: "我的 Emby 库",
                username: username,
                token: token,
                userId: userId
            )
        }
    }
    
    public func logout() {
        UserDefaults.standard.removeObject(forKey: "saved_token")
        UserDefaults.standard.removeObject(forKey: "saved_remember")
        self.currentServer = nil
    }
}
