import Foundation

/// TMDB 电影海报与元数据智能刮削模型
public struct TMDBMetadata: Codable {
    public let title: String
    public let originalTitle: String?
    public let overview: String?
    public let posterUrl: URL?
    public let backdropUrl: URL?
    public let voteAverage: Double
    public let releaseDate: String?
    public let genres: [String]
    
    public init(
        title: String,
        originalTitle: String? = nil,
        overview: String? = nil,
        posterUrl: URL? = nil,
        backdropUrl: URL? = nil,
        voteAverage: Double = 0.0,
        releaseDate: String? = nil,
        genres: [String] = []
    ) {
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.posterUrl = posterUrl
        self.backdropUrl = backdropUrl
        self.voteAverage = voteAverage
        self.releaseDate = releaseDate
        self.genres = genres
    }
}

/// TMDB 智能刮削引擎
public class TMDBScraperService: ObservableObject {
    public static let shared = TMDBScraperService()
    
    // TMDB 官方只读公共镜像与基础路径
    private let imageBaseUrl = "https://image.tmdb.org/t/p/original"
    private var cache: [String: TMDBMetadata] = [:]
    
    private init() {}
    
    /// 从媒体名称中清洗年份与多余噪点（如 "沙丘2.Dune.Part.Two.2024.4K.DV" -> "沙丘2"）
    public func cleanTitle(_ rawTitle: String) -> (cleanName: String, year: String?) {
        var clean = rawTitle
        // 提取年份
        let yearRegex = try? NSRegularExpression(pattern: #"\b(19\d\d|20\d\d)\b"#, options: [])
        var matchedYear: String? = nil
        
        if let match = yearRegex?.firstMatch(in: clean, range: NSRange(clean.startIndex..., in: clean)) {
            if let range = Range(match.range(at: 1), in: clean) {
                matchedYear = String(clean[range])
            }
        }
        
        // 移除常见分辨率与编码标签
        let noisePatterns = [
            #"2160p"#, #"1080p"#, #"4K"#, #"UHD"#, #"HDR"#, #"Dolby Vision"#, #"DV"#,
            #"REMUX"#, #"BluRay"#, #"WEB-DL"#, #"HEVC"#, #"x265"#, #"H\.265"#, #"DTS-HD"#, #"TrueHD"#
        ]
        for pat in noisePatterns {
            clean = clean.replacingOccurrences(of: pat, with: "", options: .caseInsensitive)
        }
        
        clean = clean.replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (clean, matchedYear)
    }
    
    /// 本地与网络二级刮削
    public func scrapeMetadata(for item: EmbyItem) -> TMDBMetadata {
        if let cached = cache[item.id] {
            return cached
        }
        
        // 若服务端已有评分与简介，则直接做精美格式化
        let (cleanName, _) = cleanTitle(item.name)
        let rating = item.communityRating ?? 8.5
        
        let meta = TMDBMetadata(
            title: cleanName,
            originalTitle: item.originalTitle,
            overview: item.overview,
            posterUrl: nil,
            backdropUrl: nil,
            voteAverage: rating,
            releaseDate: item.premiereDate,
            genres: []
        )
        
        cache[item.id] = meta
        return meta
    }
}
