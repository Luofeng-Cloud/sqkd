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
    @State private var showControls: Bool = true
    @State private var isLocked: Bool = false
    
    @State private var selectedAudioIndex: Int = 0
    @State private var selectedSubtitleIndex: Int = 0
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let config = playerConfig {
                KSVideoPlayerRepresentable(
                    config: config,
                    currentTime: $currentTime,
                    duration: $duration,
                    isPlaying: $isPlaying,
                    isBuffering: $isBuffering,
                    selectedAudioTrackIndex: $selectedAudioIndex,
                    selectedSubtitleTrackIndex: $selectedSubtitleIndex,
                    onPlaybackEnded: {
                        dismiss()
                    }
                )
                .ignoresSafeArea()
                .onChange(of: currentTime) { newTime in
                    PlaybackSyncManager.shared.updatePosition(seconds: newTime, isPaused: !isPlaying)
                }
                
                PlayerOverlayView(
                    title: item.name,
                    isDolbyVision: config.isDolbyVision,
                    dvBadgeText: config.dolbyVisionBadge,
                    resolutionBadge: item.resolutionBadge,
                    currentTime: $currentTime,
                    duration: $duration,
                    isPlaying: $isPlaying,
                    isBuffering: $isBuffering,
                    showControls: $showControls,
                    isLocked: $isLocked,
                    audioStreams: config.audioStreams,
                    subtitleStreams: config.subtitleStreams,
                    selectedAudioIndex: $selectedAudioIndex,
                    selectedSubtitleIndex: $selectedSubtitleIndex,
                    onDismiss: {
                        PlaybackSyncManager.shared.stopSession()
                        dismiss()
                    },
                    onSeek: { targetTime in
                        currentTime = targetTime
                        // Seek logic will update playback position
                    },
                    onTogglePlayPause: {
                        isPlaying.toggle()
                    },
                    onSeekBy: { delta in
                        let target = max(0.0, min(duration, currentTime + delta))
                        currentTime = target
                    }
                )
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
