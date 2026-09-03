import Foundation

public enum EmbyAPIError: LocalizedError {
    case invalidServerUrl
    case unauthorized
    case serverError(String)
    case decodingError(String)
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidServerUrl:
            return "无效的 Emby 服务器地址"
        case .unauthorized:
            return "登录失败，用户名或密码错误"
        case .serverError(let msg):
            return "服务器错误: \(msg)"
        case .decodingError(let msg):
            return "数据解析失败: \(msg)"
        case .networkError(let err):
            return "网络连接异常: \(err.localizedDescription)"
        }
    }
}

public class EmbyAPIService: ObservableObject {
    public static let shared = EmbyAPIService()
    
    private let session: URLSession
    private let clientName = "EmbyVision-iOS"
    private let deviceName = "iPhone"
    private let deviceId: String
    private let appVersion = "1.0.0"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        // 生成或读取持久化 DeviceId
        if let storedId = UserDefaults.standard.string(forKey: "emby_device_id") {
            self.deviceId = storedId
        } else {
            let newId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            UserDefaults.standard.set(newId, forKey: "emby_device_id")
            self.deviceId = newId
        }
    }
    
    /// 构建通用的 Emby 鉴权请求头
    private func authHeader(token: String?) -> String {
        var header = "MediaBrowser Client=\"\(clientName)\", Device=\"\(deviceName)\", DeviceId=\"\(deviceId)\", Version=\"\(appVersion)\""
        if let t = token, !t.isEmpty {
            header += ", Token=\"\(t)\""
        }
        return header
    }
    
    // MARK: - 1. 用户登录鉴权
    public func authenticate(serverUrl: String, username: String, password: String) async throws -> EmbyAuthResponse {
        var base = serverUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.hasSuffix("/") { base.removeLast() }
        if !base.lowercased().hasPrefix("http") { base = "https://" + base }
        
        guard let url = URL(string: "\(base)/emby/Users/AuthenticateByName") else {
            throw EmbyAPIError.invalidServerUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authHeader(token: nil), forHTTPHeaderField: "X-Emby-Authorization")
        
        let body: [String: String] = [
            "Username": username,
            "Pw": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmbyAPIError.serverError("无效的 HTTP 响应")
        }
        
        if httpResponse.statusCode == 401 {
            throw EmbyAPIError.unauthorized
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let errString = String(data: data, encoding: .utf8) ?? "状态码: \(httpResponse.statusCode)"
            throw EmbyAPIError.serverError(errString)
        }
        
        do {
            let authResponse = try JSONDecoder().decode(EmbyAuthResponse.self, from: data)
            return authResponse
        } catch {
            throw EmbyAPIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - 2. 获取用户媒体库 (Views)
    public func getViews(server: EmbyServer) async throws -> [EmbyItem] {
        guard let userId = server.userId, let token = server.token else {
            throw EmbyAPIError.unauthorized
        }
        guard let url = URL(string: "\(server.url)/emby/Users/\(userId)/Views") else {
            throw EmbyAPIError.invalidServerUrl
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw EmbyAPIError.serverError("无法获取媒体库视图")
        }
        
        let res = try JSONDecoder().decode(EmbyItemsResponse.self, from: data)
        return res.items
    }
    
    // MARK: - 3. 获取媒体列表 (支持按分类、分页、搜索、提取杜比视界元数据)
    public func getItems(
        server: EmbyServer,
        parentId: String? = nil,
        includeItemTypes: [String] = ["Movie", "Series"],
        sortBy: String = "SortName",
        sortOrder: String = "Ascending",
        limit: Int = 100,
        startIndex: Int = 0,
        searchTerm: String? = nil
    ) async throws -> [EmbyItem] {
        guard let userId = server.userId, let token = server.token else {
            throw EmbyAPIError.unauthorized
        }
        
        var components = URLComponents(string: "\(server.url)/emby/Users/\(userId)/Items")
        var queryItems = [
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "IncludeItemTypes", value: includeItemTypes.joined(separator: ",")),
            URLQueryItem(name: "SortBy", value: sortBy),
            URLQueryItem(name: "SortOrder", value: sortOrder),
            URLQueryItem(name: "Limit", value: "\(limit)"),
            URLQueryItem(name: "StartIndex", value: "\(startIndex)"),
            URLQueryItem(name: "Fields", value: "PrimaryImageAspectRatio,MediaStreams,Overview,Taglines,PremiereDate,CommunityRating,OfficialRating,RunTimeTicks,MediaSources,UserData")
        ]
        
        if let pid = parentId {
            queryItems.append(URLQueryItem(name: "ParentId", value: pid))
        }
        if let search = searchTerm, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "SearchTerm", value: search))
        }
        
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw EmbyAPIError.invalidServerUrl
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw EmbyAPIError.serverError("获取影片列表失败")
        }
        
        let res = try JSONDecoder().decode(EmbyItemsResponse.self, from: data)
        return res.items
    }
    
    // MARK: - 4. 获取正在继续播放的影片 (Resume Items)
    public func getResumeItems(server: EmbyServer, limit: Int = 12) async throws -> [EmbyItem] {
        guard let userId = server.userId, let token = server.token else {
            throw EmbyAPIError.unauthorized
        }
        var components = URLComponents(string: "\(server.url)/emby/Users/\(userId)/Items/Resume")
        components?.queryItems = [
            URLQueryItem(name: "Limit", value: "\(limit)"),
            URLQueryItem(name: "Fields", value: "PrimaryImageAspectRatio,MediaStreams,Overview,RunTimeTicks,MediaSources,UserData")
        ]
        guard let url = components?.url else { throw EmbyAPIError.invalidServerUrl }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")
        
        let (data, _) = try await session.data(for: request)
        let res = try JSONDecoder().decode(EmbyItemsResponse.self, from: data)
        return res.items
    }
    
    // MARK: - 5. 获取指定项目详情
    public func getItemDetail(server: EmbyServer, itemId: String) async throws -> EmbyItem {
        guard let userId = server.userId, let token = server.token else {
            throw EmbyAPIError.unauthorized
        }
        guard let url = URL(string: "\(server.url)/emby/Users/\(userId)/Items/\(itemId)") else {
            throw EmbyAPIError.invalidServerUrl
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(EmbyItem.self, from: data)
    }
    
    // MARK: - 6. 获取 PlaybackInfo (携带超级 DirectPlay 描述符，锁定原画质直出)
    public func getPlaybackInfo(server: EmbyServer, itemId: String, startPositionTicks: Int64 = 0) async throws -> PlaybackInfoResponse {
        guard let userId = server.userId, let token = server.token else {
            throw EmbyAPIError.unauthorized
        }
        
        var components = URLComponents(string: "\(server.url)/emby/Items/\(itemId)/PlaybackInfo")
        components?.queryItems = [
            URLQueryItem(name: "UserId", value: userId),
            URLQueryItem(name: "StartTimeTicks", value: "\(startPositionTicks)"),
            URLQueryItem(name: "IsPlayback", value: "true"),
            URLQueryItem(name: "AutoOpenLiveStream", value: "true"),
            URLQueryItem(name: "MaxStreamingBitrate", value: "250000000")
        ]
        
        guard let url = components?.url else {
            throw EmbyAPIError.invalidServerUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")
        
        // 注入 DirectPlay 描述载荷
        let deviceProfilePayload = [
            "DeviceProfile": DirectPlayProfile.makeDeviceProfile()
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: deviceProfilePayload)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw EmbyAPIError.serverError("无法获取播放信息")
        }
        
        return try JSONDecoder().decode(PlaybackInfoResponse.self, from: data)
    }
    
    // MARK: - 7. 播放进度同步上报 (保证 iPhone 与电脑/电视进度实时一致)
    public func reportPlaybackStart(server: EmbyServer, itemId: String, playSessionId: String, positionTicks: Int64) async {
        guard let token = server.token, let url = URL(string: "\(server.url)/emby/Sessions/Playing") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")
        
        let body: [String: Any] = [
            "ItemId": itemId,
            "PlaySessionId": playSessionId,
            "PositionTicks": positionTicks,
            "CanSeek": true
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await session.data(for: request)
    }
    
    public func reportPlaybackProgress(server: EmbyServer, itemId: String, playSessionId: String, positionTicks: Int64, isPaused: Bool) async {
        guard let token = server.token, let url = URL(string: "\(server.url)/emby/Sessions/Playing/Progress") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")
        
        let body: [String: Any] = [
            "ItemId": itemId,
            "PlaySessionId": playSessionId,
            "PositionTicks": positionTicks,
            "IsPaused": isPaused,
            "EventName": isPaused ? "Pause" : "TimeUpdate"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await session.data(for: request)
    }
    
    public func reportPlaybackStopped(server: EmbyServer, itemId: String, playSessionId: String, positionTicks: Int64) async {
        guard let token = server.token, let url = URL(string: "\(server.url)/emby/Sessions/Playing/Stopped") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")
        
        let body: [String: Any] = [
            "ItemId": itemId,
            "PlaySessionId": playSessionId,
            "PositionTicks": positionTicks
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await session.data(for: request)
    }
}
