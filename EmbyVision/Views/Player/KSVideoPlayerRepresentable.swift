import SwiftUI
import AVFoundation
import MediaPlayer
import AVKit

#if canImport(KSPlayer)
import KSPlayer
#endif

public struct PlayerConfiguration {
    public let url: URL
    public let title: String
    public let isDolbyVision: Bool
    public let dolbyVisionBadge: String?
    public let initialPositionSeconds: Double
    public let audioStreams: [MediaStream]
    public let subtitleStreams: [MediaStream]
    
    public init(
        url: URL,
        title: String,
        isDolbyVision: Bool = false,
        dolbyVisionBadge: String? = nil,
        initialPositionSeconds: Double = 0.0,
        audioStreams: [MediaStream] = [],
        subtitleStreams: [MediaStream] = []
    ) {
        self.url = url
        self.title = title
        self.isDolbyVision = isDolbyVision
        self.dolbyVisionBadge = dolbyVisionBadge
        self.initialPositionSeconds = initialPositionSeconds
        self.audioStreams = audioStreams
        self.subtitleStreams = subtitleStreams
    }
}

public struct VideoPlayerCoreView: View {
    public let config: PlayerConfiguration
    @Binding public var currentTime: Double
    @Binding public var duration: Double
    @Binding public var isPlaying: Bool
    @Binding public var isBuffering: Bool
    public let onPlaybackEnded: () -> Void
    
    public var body: some View {
        #if canImport(KSPlayer)
        ksPlayerView
        #else
        avPlayerFallbackView
        #endif
    }
    
    #if canImport(KSPlayer)
    @ViewBuilder
    private var ksPlayerView: some View {
        let options = KSOptions()
        KSVideoPlayerView(url: config.url, options: options, title: config.title)
            .ignoresSafeArea()
            .onAppear {
                options.hardwareDecode = true
                KSOptions.firstPlayerType = KSMEPlayer.self
                KSOptions.secondPlayerType = KSAVPlayer.self
                options.canProcessPicture = true
                options.preferredForwardBufferDuration = 30.0
            }
    }
    #endif
    
    private var avPlayerFallbackView: some View {
        AVPlayerFallbackView(url: config.url, initialSeconds: config.initialPositionSeconds) {
            onPlaybackEnded()
        }
        .ignoresSafeArea()
    }
}

struct AVPlayerFallbackView: UIViewControllerRepresentable {
    let url: URL
    let initialSeconds: Double
    let onEnd: () -> Void
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        
        if initialSeconds > 0 {
            let target = CMTime(seconds: initialSeconds, preferredTimescale: 600)
            player.seek(to: target)
        }
        player.play()
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            onEnd()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
