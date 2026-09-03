import SwiftUI

public struct VideoPlayerContainerView: View {
    public let server: EmbyServer
    public let item: EmbyItem
    @Environment(\.dismiss) private var dismiss
    
    @State private var playerConfig: PlayerConfiguration?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    @State private var currentTime: Double = 0.0
    @State private var duration: Double = 0.0
    @State private var isPlaying: Bool = true
    @State private var isBuffering: Bool = false
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let config = playerConfig {
                VideoPlayerCoreView(
                    config: config,
                    currentTime: $currentTime,
                    duration: $duration,
                    isPlaying: $isPlaying,
                    isBuffering: $isBuffering,
                    onPlaybackEnded: {
                        dismiss()
                    }
                )
                .ignoresSafeArea()
                
                // 顶部返回与杜比视界高光提示浮层
                VStack {
                    HStack {
                        Button(action: {
                            PlaybackSyncManager.shared.stopSession()
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        if config.isDolbyVision {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10, weight: .black))
                                Text(config.dolbyVisionBadge ?? "DOLBY VISION")
                                    .font(.system(size: 10, weight: .heavy))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.98, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.6, blue: 0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.black)
                            .cornerRadius(5)
                            .shadow(color: Color.yellow.opacity(0.4), radius: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    Spacer()
                }
            } else if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("正在获取原画直链与杜比视界码流...")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.yellow)
                    Text(error)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("返回") {
                        dismiss()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            loadPlaybackInfo()
        }
        .onDisappear {
            PlaybackSyncManager.shared.stopSession()
        }
    }
    
    private func loadPlaybackInfo() {
        Task {
            do {
                let startTicks = item.userData?.playbackPositionTicks ?? 0
                let playbackInfo = try await EmbyAPIService.shared.getPlaybackInfo(
                    server: server,
                    itemId: item.id,
                    startPositionTicks: startTicks
                )
                
                guard let firstSource = playbackInfo.mediaSources.first,
                      let directUrl = firstSource.resolveDirectPlayUrl(serverUrl: server.url, itemId: item.id, token: server.token) else {
                    await MainActor.run {
                        self.errorMessage = "无法解析到有效的视频直链"
                        self.isLoading = false
                    }
                    return
                }
                
                let streams = firstSource.mediaStreams ?? item.mediaStreams ?? []
                let audioStreams = streams.filter { $0.type == .audio }
                let subtitleStreams = streams.filter { $0.type == .subtitle }
                let isDV = item.isDolbyVision || streams.contains { $0.dynamicRange.isDolbyVision }
                let dvBadge = item.dolbyVisionBadge ?? streams.first(where: { $0.dynamicRange.isDolbyVision })?.dolbyVisionBadgeText
                
                let resumeSeconds = item.userData?.playbackPositionSeconds ?? 0.0
                
                await MainActor.run {
                    self.playerConfig = PlayerConfiguration(
                        url: directUrl,
                        title: item.name,
                        isDolbyVision: isDV,
                        dolbyVisionBadge: dvBadge,
                        initialPositionSeconds: resumeSeconds,
                        audioStreams: audioStreams,
                        subtitleStreams: subtitleStreams
                    )
                    self.isLoading = false
                    
                    PlaybackSyncManager.shared.startSession(
                        server: server,
                        itemId: item.id,
                        playSessionId: playbackInfo.playSessionId,
                        initialSeconds: resumeSeconds
                    )
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
