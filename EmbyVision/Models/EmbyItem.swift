import Foundation

public struct EmbyItemsResponse: Codable {
    public let items: [EmbyItem]
    public let totalRecordCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case items = "Items"
        case totalRecordCount = "TotalRecordCount"
    }
}

public struct UserData: Codable, Hashable {
    public let playbackPositionTicks: Int64?
    public let playCount: Int?
    public let isFavorite: Bool?
    public let played: Bool?
    public let key: String?
    
    enum CodingKeys: String, CodingKey {
        case playbackPositionTicks = "PlaybackPositionTicks"
        case playCount = "PlayCount"
        case isFavorite = "IsFavorite"
        case played = "Played"
        case key = "Key"
    }
    
    public var playbackPositionSeconds: Double {
        guard let ticks = playbackPositionTicks else { return 0.0 }
        return Double(ticks) / 10_000_000.0
    }
}

public struct EmbyItem: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let originalTitle: String?
    public let serverId: String?
    public let type: String
    public let runTimeTicks: Int64?
    public let overview: String?
    public let communityRating: Double?
    public let officialRating: String?
    public let premiereDate: String?
    public let productionYear: Int?
    public let container: String?
    
    // Series / Season specifics
    public let seriesName: String?
    public let seriesId: String?
    public let seasonName: String?
    public let seasonId: String?
    public let indexNumber: Int?       // 集数
    public let parentIndexNumber: Int? // 季数
    
    // Images
    public let imageTags: [String: String]?
    public let backdropImageTags: [String]?
    
    // Streams & User data
    public let mediaStreams: [MediaStream]?
    public let mediaSources: [MediaSourceInfo]?
    public let userData: UserData?
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case originalTitle = "OriginalTitle"
        case serverId = "ServerId"
        case type = "Type"
        case runTimeTicks = "RunTimeTicks"
        case overview = "Overview"
        case communityRating = "CommunityRating"
        case officialRating = "OfficialRating"
        case premiereDate = "PremiereDate"
        case productionYear = "ProductionYear"
        case container = "Container"
        case seriesName = "SeriesName"
        case seriesId = "SeriesId"
        case seasonName = "SeasonName"
        case seasonId = "SeasonId"
        case indexNumber = "IndexNumber"
        case parentIndexNumber = "ParentIndexNumber"
        case imageTags = "ImageTags"
        case backdropImageTags = "BackdropImageTags"
        case mediaStreams = "MediaStreams"
        case mediaSources = "MediaSources"
        case userData = "UserData"
    }
    
    // 基础视频属性辅助计算
    public var durationSeconds: Double {
        guard let ticks = runTimeTicks else { return 0.0 }
        return Double(ticks) / 10_000_000.0
    }
    
    public var durationFormatted: String {
        let total = Int(durationSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    /// 获取主视频流
    public var primaryVideoStream: MediaStream? {
        if let streams = mediaStreams {
            return streams.first { $0.type == .video }
        }
        if let firstSource = mediaSources?.first, let streams = firstSource.mediaStreams {
            return streams.first { $0.type == .video }
        }
        return nil
    }
    
    /// 获取主音频流
    public var primaryAudioStream: MediaStream? {
        if let streams = mediaStreams {
            return streams.first { $0.type == .audio && $0.isDefault } ?? streams.first { $0.type == .audio }
        }
        if let firstSource = mediaSources?.first, let streams = firstSource.mediaStreams {
            return streams.first { $0.type == .audio && $0.isDefault } ?? streams.first { $0.type == .audio }
        }
        return nil
    }
    
    /// 是否为杜比视界
    public var isDolbyVision: Bool {
        return primaryVideoStream?.dynamicRange.isDolbyVision ?? false
    }
    
    /// 是否为 4K / UHD
    public var is4K: Bool {
        guard let stream = primaryVideoStream, let width = stream.width else { return false }
        return width >= 3800
    }
    
    /// 杜比视界角标字符串（如 "DV P8.1", "DV P5"）
    public var dolbyVisionBadge: String? {
        return primaryVideoStream?.dolbyVisionBadgeText
    }
    
    /// 视频分辨率显示文本（如 "4K 2160p", "1080p"）
    public var resolutionBadge: String {
        guard let stream = primaryVideoStream else { return "" }
        if let height = stream.height {
            if height >= 2100 { return "4K UHD" }
            if height >= 1000 { return "1080p" }
            if height >= 700 { return "720p" }
            return "\(height)p"
        }
        return ""
    }
    
    /// 构造海报图片 URL
    public func posterUrl(serverUrl: String, apiKey: String?) -> URL? {
        if let tag = imageTags?["Primary"] {
            var urlString = "\(serverUrl)/emby/Items/\(id)/Images/Primary?maxHeight=600&tag=\(tag)&quality=90"
            if let key = apiKey {
                urlString += "&api_key=\(key)"
            }
            return URL(string: urlString)
        }
        return nil
    }
    
    /// 构造背景剧照 URL
    public func backdropUrl(serverUrl: String, apiKey: String?) -> URL? {
        if let tags = backdropImageTags, let firstTag = tags.first {
            var urlString = "\(serverUrl)/emby/Items/\(id)/Images/Backdrop/0?maxWidth=1920&tag=\(firstTag)&quality=90"
            if let key = apiKey {
                urlString += "&api_key=\(key)"
            }
            return URL(string: urlString)
        }
        return nil
    }
}
