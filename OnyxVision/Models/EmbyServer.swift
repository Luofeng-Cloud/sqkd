import Foundation

public struct EmbyServer: Codable, Identifiable, Equatable {
    public var id: String { "\(url)_\(userId ?? "")" }
    
    public var url: String
    public var name: String
    public var username: String
    public var token: String?
    public var userId: String?
    public var isHttps: Bool {
        return url.lowercased().hasPrefix("https://")
    }
    
    public init(url: String, name: String = "Emby Server", username: String = "", token: String? = nil, userId: String? = nil) {
        // 自动标准化 URL：移除结尾的斜杠
        var cleaned = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasSuffix("/") {
            cleaned.removeLast()
        }
        if !cleaned.lowercased().hasPrefix("http://") && !cleaned.lowercased().hasPrefix("https://") {
            cleaned = "https://" + cleaned
        }
        self.url = cleaned
        self.name = name
        self.username = username
        self.token = token
        self.userId = userId
    }
}

public struct EmbyAuthResponse: Codable {
    public let user: EmbyUser
    public let accessToken: String
    public let serverId: String?
    
    enum CodingKeys: String, CodingKey {
        case user = "User"
        case accessToken = "AccessToken"
        case serverId = "ServerId"
    }
}

public struct EmbyUser: Codable {
    public let id: String
    public let name: String
    public let hasPassword: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case hasPassword = "HasPassword"
    }
}

public struct EmbySystemInfo: Codable {
    public let serverName: String?
    public let version: String?
    public let id: String?
    public let operatingSystem: String?
    
    enum CodingKeys: String, CodingKey {
        case serverName = "ServerName"
        case version = "Version"
        case id = "Id"
        case operatingSystem = "OperatingSystem"
    }
}
