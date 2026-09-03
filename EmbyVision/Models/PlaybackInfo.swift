import Foundation

public struct PlaybackInfoResponse: Codable {
    public let mediaSources: [MediaSourceInfo]
    public let playSessionId: String?
    
    enum CodingKeys: String, CodingKey {
        case mediaSources = "MediaSources"
        case playSessionId = "PlaySessionId"
    }
}

public struct MediaSourceInfo: Codable, Identifiable, Hashable {
    public var id: String { id_field ?? UUID().uuidString }
    
    private let id_field: String?
    public let name: String?
    public let path: String?
    public let container: String?
    public let size: Int64?
    public let bitRate: Int?
    public let supportsDirectPlay: Bool?
    public let supportsDirectStream: Bool?
    public let supportsTranscoding: Bool?
    public let directStreamUrl: String?
    public let transcodingUrl: String?
    public let mediaStreams: [MediaStream]?
    public let eTag: String?
    
    enum CodingKeys: String, CodingKey {
        case id_field = "Id"
        case name = "Name"
        case path = "Path"
        case container = "Container"
        case size = "Size"
        case bitRate = "BitRate"
        case supportsDirectPlay = "SupportsDirectPlay"
        case supportsDirectStream = "SupportsDirectStream"
        case supportsTranscoding = "SupportsTranscoding"
        case directStreamUrl = "DirectStreamUrl"
        case transcodingUrl = "TranscodingUrl"
        case mediaStreams = "MediaStreams"
        case eTag = "ETag"
    }
    
    /// 构建纯粹的 Direct Play 直链，避免任何服务端转码
    public func resolveDirectPlayUrl(serverUrl: String, itemId: String, token: String?) -> URL? {
        // 如果服务器返回了直链相对路径，直接拼接
        if let direct = directStreamUrl, !direct.isEmpty {
            let fullStr = direct.hasPrefix("http") ? direct : "\(serverUrl)\(direct)"
            return URL(string: fullStr)
        }
        
        // 构造标准的 Emby Direct Play 静态直链格式
        let fileExt = container ?? "mkv"
        var urlStr = "\(serverUrl)/emby/Videos/\(itemId)/stream.\(fileExt)?Static=true&MediaSourceId=\(id)"
        if let t = token {
            urlStr += "&api_key=\(t)"
        }
        return URL(string: urlStr)
    }
}
