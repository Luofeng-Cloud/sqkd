import Foundation
import Combine

/// 苹果官方 iCloud 多端无缝续播同步引擎
public class iCloudSyncManager: ObservableObject {
    public static let shared = iCloudSyncManager()
    
    private let kvStore = NSUbiquitousKeyValueStore.default
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var syncEnabled: Bool = true
    
    private init() {
        self.syncEnabled = UserDefaults.standard.object(forKey: "onyx_icloud_sync_enabled") as? Bool ?? true
        
        // 监听来自其他设备（如 iPad / 另一台 iPhone）的 iCloud 外部更新通知
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] notification in
                self?.handleExternalCloudChange(notification)
            }
            .store(in: &cancellables)
        
        // 初次同步
        kvStore.synchronize()
    }
    
    /// 保存某个媒体的播放进度到 iCloud
    public func savePlaybackPosition(itemId: String, title: String, seconds: Double, duration: Double, serverUrl: String) {
        guard syncEnabled else { return }
        
        let payload: [String: Any] = [
            "itemId": itemId,
            "title": title,
            "seconds": seconds,
            "duration": duration,
            "timestamp": Date().timeIntervalSince1970,
            "serverUrl": serverUrl
        ]
        
        let key = "progress_\(itemId)"
        kvStore.set(payload, forKey: key)
        kvStore.synchronize()
    }
    
    /// 从 iCloud 获取指定媒体的最新续播进度
    public func getPlaybackPosition(itemId: String) -> (seconds: Double, timestamp: Date)? {
        let key = "progress_\(itemId)"
        guard let dict = kvStore.dictionary(forKey: key),
              let seconds = dict["seconds"] as? Double,
              let ts = dict["timestamp"] as? Double else {
            return nil
        }
        return (seconds, Date(timeIntervalSince1970: ts))
    }
    
    /// 外部云端更新回调
    private func handleExternalCloudChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else { return }
        
        if reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
}
