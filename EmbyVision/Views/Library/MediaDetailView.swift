import SwiftUI

public struct MediaDetailView: View {
    public let item: EmbyItem
    public let server: EmbyServer
    
    @State private var detailedItem: EmbyItem?
    @State private var seasons: [EmbyItem] = []
    @State private var episodes: [EmbyItem] = []
    @State private var selectedSeason: EmbyItem?
    
    @State private var activePlayingItem: EmbyItem?
    @State private var showPlayer = false
    @State private var isLoadingEpisodes = false
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: 顶部海报剧照背景大图
                heroBackdrop
                
                // MARK: 核心内容区域
                VStack(alignment: .leading, spacing: 18) {
                    // 标题与基本信息
                    titleSection
                    
                    // 极客规格角标（杜比视界 Profile / 4K / 原盘直出 / 音频编码）
                    technicalBadgesSection
                    
                    // 播放按钮组
                    playButtonsSection
                    
                    // 剧情梗概
                    overviewSection
                    
                    // 如果是剧集，展示季与选集列表
                    if item.type == "Series" {
                        episodesSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color(white: 0.07).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPlayer) {
            if let playTarget = activePlayingItem {
                VideoPlayerContainerView(server: server, item: playTarget)
            }
        }
        .onAppear {
            loadDetails()
        }
    }
    
    // MARK: - 顶部剧照横幅
    private var heroBackdrop: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: item.backdropUrl(serverUrl: server.url, apiKey: server.token)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(white: 0.12))
                        .aspectRatio(16/9, contentMode: .fill)
                }
            }
            .frame(maxHeight: 260)
            .clipped()
            
            // 渐变过渡遮罩
            LinearGradient(
                colors: [Color.clear, Color(white: 0.07).opacity(0.8), Color(white: 0.07)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
        }
    }
    
    // MARK: - 标题与年份时长
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            if let original = item.originalTitle, original != item.name {
                Text(original)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 12) {
                if let year = item.productionYear {
                    Text("\(year)")
                }
                if let duration = detailedItem?.durationFormatted ?? (item.runTimeTicks != nil ? item.durationFormatted : nil) {
                    Text(duration)
                }
                if let rating = item.communityRating {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", rating))
                            .fontWeight(.bold)
                    }
                }
            }
            .font(.subheadline)
            .foregroundColor(.gray)
        }
    }
    
    // MARK: - 技术规格药丸角标（杜比视界 & 4K 原生呈现）
    private var technicalBadgesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                let currentItem = detailedItem ?? item
                let videoStream = currentItem.primaryVideoStream
                let audioStream = currentItem.primaryAudioStream
                
                // 杜比视界专属金光角标
                if currentItem.isDolbyVision {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .black))
                        Text(currentItem.dolbyVisionBadge ?? "DOLBY VISION")
                            .font(.system(size: 11, weight: .heavy))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.6, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.black)
                    .cornerRadius(6)
                    .shadow(color: Color.yellow.opacity(0.3), radius: 5)
                }
                
                // 4K UHD 角标
                if !currentItem.resolutionBadge.isEmpty {
                    Text(currentItem.resolutionBadge)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                
                // 视频编码（如 HEVC 10-bit）
                if let codec = videoStream?.codec {
                    let depth = videoStream?.bitDepth != nil ? "\(videoStream!.bitDepth!)bit" : ""
                    Text("\(codec.uppercased()) \(depth)".trimmingCharacters(in: .whitespaces))
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white.opacity(0.9))
                        .cornerRadius(6)
                }
                
                // 音频编码（如 TrueHD Atmos / DTS-HD / EAC3）
                if let audioCodec = audioStream?.codec {
                    let ch = audioStream?.channelDescription ?? ""
                    Text("\(audioCodec.uppercased()) \(ch)".trimmingCharacters(in: .whitespaces))
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.25))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                
                // 原画直出标识
                Text("Direct Play 零转码")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(6)
            }
        }
    }
    
    // MARK: - 播放按钮
    private var playButtonsSection: some View {
        VStack(spacing: 10) {
            Button(action: {
                activePlayingItem = detailedItem ?? item
                showPlayer = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.headline)
                    
                    if let resume = (detailedItem ?? item).userData?.playbackPositionSeconds, resume > 60 {
                        let mins = Int(resume / 60)
                        Text("继续播放 (从第 \(mins) 分钟)")
                            .font(.headline)
                    } else {
                        Text("立即播放 (原画直出)")
                            .font(.headline)
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    (detailedItem ?? item).isDolbyVision ?
                    LinearGradient(colors: [Color(red: 0.98, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.6, blue: 0.1)], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [Color.white, Color(white: 0.9)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
    }
    
    // MARK: - 剧情简介
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("剧情简介")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(item.overview ?? "暂无剧情介绍。")
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
    }
    
    // MARK: - 剧集选集区域
    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("剧集列表")
                .font(.headline)
                .foregroundColor(.white)
            
            if isLoadingEpisodes {
                ProgressView().tint(.white)
            } else {
                ForEach(episodes) { ep in
                    Button(action: {
                        activePlayingItem = ep
                        showPlayer = true
                    }) {
                        HStack(spacing: 12) {
                            // 单集缩略图
                            AsyncImage(url: ep.posterUrl(serverUrl: server.url, apiKey: server.token)) { phase in
                                if let img = phase.image {
                                    img.resizable().aspectRatio(16/9, contentMode: .fill)
                                } else {
                                    Rectangle().fill(Color(white: 0.15))
                                }
                            }
                            .frame(width: 100, height: 60)
                            .cornerRadius(6)
                            .clipped()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("第 \(ep.indexNumber ?? 1) 集 · \(ep.name)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                if let duration = ep.durationFormatted as String?, !duration.isEmpty {
                                    Text(duration)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private func loadDetails() {
        Task {
            if let full = try? await EmbyAPIService.shared.getItemDetail(server: server, itemId: item.id) {
                await MainActor.run {
                    self.detailedItem = full
                }
            }
            
            if item.type == "Series" {
                await MainActor.run { self.isLoadingEpisodes = true }
                if let eps = try? await EmbyAPIService.shared.getItems(
                    server: server,
                    parentId: item.id,
                    includeItemTypes: ["Episode"],
                    sortBy: "SortName",
                    limit: 100
                ) {
                    await MainActor.run {
                        self.episodes = eps
                        self.isLoadingEpisodes = false
                    }
                }
            }
        }
    }
}
