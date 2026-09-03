import Foundation

public enum VideoDynamicRange: String, Codable {
    case sdr = "SDR"
    case hdr10 = "HDR10"
    case hdr10Plus = "HDR10+"
    case hlg = "HLG"
    case dolbyVision = "DOVI"
    case dolbyVisionHDR10 = "DOVI_HDR10"
    case unknown = "Unknown"
    
    public var displayName: String {
        switch self {
        case .dolbyVision, .dolbyVisionHDR10:
            return "Dolby Vision"
        case .hdr10Plus:
            return "HDR10+"
        case .hdr10:
            return "HDR10"
        case .hlg:
            return "HLG"
        case .sdr:
            return "SDR"
        case .unknown:
            return ""
        }
    }
    
    public var isDolbyVision: Bool {
        return self == .dolbyVision || self == .dolbyVisionHDR10
    }
}

public struct MediaStream: Codable, Identifiable, Hashable {
    public var id: String { "\(index)_\(type.rawValue)" }
    
    public let index: Int
    public let type: StreamType
    public let codec: String?
    public let language: String?
    public let title: String?
    public let displayTitle: String?
    public let isDefault: Bool
    public let isForced: Bool
    public let isExternal: Bool
    
    // Video specific
    public let width: Int?
    public let height: Int?
    public let bitRate: Int?
    public let bitDepth: Int?
    public let colorSpace: String?
    public let colorTransfer: String?
    public let colorPrimaries: String?
    public let videoRange: String?
    public let videoRangeType: String?
    public let extendedVideoType: String?
    public let extendedVideoSubType: String?
    public let videoDoViTitle: String?
    public let dvProfile: Int?
    public let dvLevel: Int?
    public let rpuPresentFlag: Int?
    public let elPresentFlag: Int?
    public let blPresentFlag: Int?
    
    // Audio specific
    public let channels: Int?
    public let sampleRate: Int?
    public let profile: String?
    
    // Subtitle specific
    public let deliveryUrl: String?
    
    public enum StreamType: String, Codable {
        case video = "Video"
        case audio = "Audio"
        case subtitle = "Subtitle"
        case embeddedImage = "EmbeddedImage"
        case unknown = "Unknown"
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            self = StreamType(rawValue: raw) ?? .unknown
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case index = "Index"
        case type = "Type"
        case codec = "Codec"
        case language = "Language"
        case title = "Title"
        case displayTitle = "DisplayTitle"
        case isDefault = "IsDefault"
        case isForced = "IsForced"
        case isExternal = "IsExternal"
        case width = "Width"
        case height = "Height"
        case bitRate = "BitRate"
        case bitDepth = "BitDepth"
        case colorSpace = "ColorSpace"
        case colorTransfer = "ColorTransfer"
        case colorPrimaries = "ColorPrimaries"
        case videoRange = "VideoRange"
        case videoRangeType = "VideoRangeType"
        case extendedVideoType = "ExtendedVideoType"
        case extendedVideoSubType = "ExtendedVideoSubType"
        case videoDoViTitle = "VideoDoViTitle"
        case dvProfile = "DvProfile"
        case dvLevel = "DvLevel"
        case rpuPresentFlag = "RpuPresentFlag"
        case elPresentFlag = "ElPresentFlag"
        case blPresentFlag = "BlPresentFlag"
        case channels = "Channels"
        case sampleRate = "SampleRate"
        case profile = "Profile"
        case deliveryUrl = "DeliveryUrl"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decodeIfPresent(Int.self, forKey: .index) ?? 0
        type = try container.decodeIfPresent(StreamType.self, forKey: .type) ?? .unknown
        codec = try container.decodeIfPresent(String.self, forKey: .codec)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        displayTitle = try container.decodeIfPresent(String.self, forKey: .displayTitle)
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        isForced = try container.decodeIfPresent(Bool.self, forKey: .isForced) ?? false
        isExternal = try container.decodeIfPresent(Bool.self, forKey: .isExternal) ?? false
        
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
        bitRate = try container.decodeIfPresent(Int.self, forKey: .bitRate)
        bitDepth = try container.decodeIfPresent(Int.self, forKey: .bitDepth)
        colorSpace = try container.decodeIfPresent(String.self, forKey: .colorSpace)
        colorTransfer = try container.decodeIfPresent(String.self, forKey: .colorTransfer)
        colorPrimaries = try container.decodeIfPresent(String.self, forKey: .colorPrimaries)
        videoRange = try container.decodeIfPresent(String.self, forKey: .videoRange)
        videoRangeType = try container.decodeIfPresent(String.self, forKey: .videoRangeType)
        extendedVideoType = try container.decodeIfPresent(String.self, forKey: .extendedVideoType)
        extendedVideoSubType = try container.decodeIfPresent(String.self, forKey: .extendedVideoSubType)
        videoDoViTitle = try container.decodeIfPresent(String.self, forKey: .videoDoViTitle)
        dvProfile = try container.decodeIfPresent(Int.self, forKey: .dvProfile)
        dvLevel = try container.decodeIfPresent(Int.self, forKey: .dvLevel)
        rpuPresentFlag = try container.decodeIfPresent(Int.self, forKey: .rpuPresentFlag)
        elPresentFlag = try container.decodeIfPresent(Int.self, forKey: .elPresentFlag)
        blPresentFlag = try container.decodeIfPresent(Int.self, forKey: .blPresentFlag)
        
        channels = try container.decodeIfPresent(Int.self, forKey: .channels)
        sampleRate = try container.decodeIfPresent(Int.self, forKey: .sampleRate)
        profile = try container.decodeIfPresent(String.self, forKey: .profile)
        deliveryUrl = try container.decodeIfPresent(String.self, forKey: .deliveryUrl)
    }
    
    /// 解析当前视频流的动态范围，精确识别杜比视界
    public var dynamicRange: VideoDynamicRange {
        if let doviTitle = videoDoViTitle, !doviTitle.isEmpty {
            return .dolbyVision
        }
        if let subType = extendedVideoSubType, subType.localizedCaseInsensitiveContains("dovi") || subType.localizedCaseInsensitiveContains("dv") {
            return .dolbyVision
        }
        if let range = videoRange {
            let upper = range.uppercased()
            if upper.contains("DOVI") || upper.contains("DOLBY") {
                return .dolbyVision
            }
            if upper.contains("HDR10+") {
                return .hdr10Plus
            }
            if upper.contains("HDR") {
                return .hdr10
            }
            if upper.contains("HLG") {
                return .hlg
            }
        }
        if let transfer = colorTransfer?.lowercased() {
            if transfer.contains("smpte2084") || transfer.contains("arib-std-b67") {
                return .hdr10
            }
        }
        return .sdr
    }
    
    /// 提取格式化杜比视界 Profile 标签，例如 "DV P8.1"、"DV P5"
    public var dolbyVisionBadgeText: String? {
        guard dynamicRange.isDolbyVision else { return nil }
        if let p = dvProfile {
            if let l = dvLevel {
                return "DV P\(p).\(l)"
            }
            return "DV P\(p)"
        }
        if let title = videoDoViTitle, !title.isEmpty {
            return title
        }
        return "Dolby Vision"
    }
    
    /// 音频声道格式化（如 "5.1 声道", "7.1 全景声"）
    public var channelDescription: String {
        guard let ch = channels else { return "" }
        switch ch {
        case 1: return "单声道"
        case 2: return "立体声 2.0"
        case 6: return "5.1 环绕声"
        case 8: return "7.1 全景声"
        default: return "\(ch) 声道"
        }
    }
}
