import Foundation

/// 媒体源协议类型定义
public enum MediaSourceType: String, Codable, CaseIterable {
    case emby = "Emby"
    case jellyfin = "Jellyfin"
    case alist = "Alist (全网盘挂载)"
    case webdav = "WebDAV (NAS/云盘)"
    
    public var iconName: String {
        switch self {
        case .emby: return "server.rack"
        case .jellyfin: return "play.tv.fill"
        case .alist: return "externaldrive.connected.to.line.below"
        case .webdav: return "network"
        }
    }
    
    public var supportedNetdisksBadge: String? {
        switch self {
        case .alist: return "支持百度/阿里/115/夸克"
        case .webdav: return "支持群晖/威联通/Alist"
        default: return nil
        }
    }
}

/// 统一媒体源配置模型
public struct UnifiedMediaSource: Identifiable, Codable {
    public let id: String
    public var name: String
    public var type: MediaSourceType
    public var url: String
    public var username: String
    public var token: String?
    public var isConnected: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: MediaSourceType,
        url: String,
        username: String,
        token: String? = nil,
        isConnected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.url = url
        self.username = username
        self.token = token
        self.isConnected = isConnected
    }
}

/// 多源聚合中心管理服务
public class MultiSourceManager: ObservableObject {
    public static let shared = MultiSourceManager()
    
    @Published public var sources: [UnifiedMediaSource] = []
    
    private let storageKey = "onyx_unified_media_sources"
    
    private init() {
        loadSources()
    }
    
    public func loadSources() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let list = try? JSONDecoder().decode([UnifiedMediaSource].self, from: data) {
            self.sources = list
        } else {
            // 预填充默认已配置的 Emby 服务器
            let defaultSource = UnifiedMediaSource(
                id: "default_okemby",
                name: "OKEmby 旗舰影视库",
                type: .emby,
                url: "https://link01.okemby.org:8443",
                username: "LuoFeng",
                token: nil,
                isConnected: true
            )
            self.sources = [defaultSource]
            saveSources()
        }
    }
    
    public func addSource(_ source: UnifiedMediaSource) {
        sources.append(source)
        saveSources()
    }
    
    public func removeSource(id: String) {
        sources.removeAll { $0.id == id }
        saveSources()
    }
    
    private func saveSources() {
        if let data = try? JSONEncoder().encode(sources) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
