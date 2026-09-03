import SwiftUI
import AVFoundation
import MediaPlayer
import AVKit

#if canImport(KSPlayer)
import KSPlayer
#endif

/// 播放器配置模型
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

/// 原生级高性能播放器容器（支持 KSPlayer 杜比视界硬件解码，并自适应降级至 AVPlayer 引擎）
public struct KSVideoPlayerRepresentable: UIViewControllerRepresentable {
    public let config: PlayerConfiguration
    @Binding public var currentTime: Double
    @Binding public var duration: Double
    @Binding public var isPlaying: Bool
    @Binding public var isBuffering: Bool
    @Binding public var selectedAudioTrackIndex: Int
    @Binding public var selectedSubtitleTrackIndex: Int
    public let onPlaybackEnded: () -> Void
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .black
        
        #if canImport(KSPlayer)
        // 1. 配置 KSPlayer 超强杜比视界渲染内核
        KSOptions.firstPlayerType = KSMEPlayer.self
        KSOptions.secondPlayerType = KSAVPlayer.self
        KSOptions.hardwareDecode = true
        KSOptions.canProcessPicture = true
        KSOptions.preferredForwardBufferDuration = 30.0 // 充足缓冲保证4K原画不卡
        
        let player = IOSVideoPlayerView()
        player.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(player)
        
        NSLayoutConstraint.activate([
            player.topAnchor.constraint(equalTo: vc.view.topAnchor),
            player.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            player.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            player.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
        ])
        
        context.coordinator.ksPlayer = player
        
        // 启动播放并跳至断点位置
        player.set(url: config.url, options: KSOptions())
        if config.initialPositionSeconds > 0 {
            player.seek(time: TimeInterval(config.initialPositionSeconds)) { _ in }
        }
        player.play()
        context.coordinator.setupKSPlayerCallbacks(player)
        
        #else
        // 2. 备用原生 AVPlayer 硬件解码管线（针对 MP4 杜比视界 Profile 5 及常规 HLS 原生硬件直出）
        let avPlayer = AVPlayer(url: config.url)
        let playerLayer = AVPlayerLayer(player: avPlayer)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = vc.view.bounds
        vc.view.layer.addSublayer(playerLayer)
        
        context.coordinator.avPlayer = avPlayer
        context.coordinator.avPlayerLayer = playerLayer
        
        if config.initialPositionSeconds > 0 {
            let cmTime = CMTime(seconds: config.initialPositionSeconds, preferredTimescale: 600)
            avPlayer.seek(to: cmTime)
        }
        avPlayer.play()
        context.coordinator.setupAVPlayerCallbacks(avPlayer, vc: vc)
        #endif
        
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        #if !canImport(KSPlayer)
        context.coordinator.avPlayerLayer?.frame = uiViewController.view.bounds
        #endif
    }
    
    public class Coordinator: NSObject {
        var parent: KSVideoPlayerRepresentable
        var timeObserverToken: Any?
        
        #if canImport(KSPlayer)
        weak var ksPlayer: IOSVideoPlayerView?
        #endif
        var avPlayer: AVPlayer?
        weak var avPlayerLayer: AVPlayerLayer?
        
        init(_ parent: KSVideoPlayerRepresentable) {
            self.parent = parent
        }
        
        #if canImport(KSPlayer)
        func setupKSPlayerCallbacks(_ player: IOSVideoPlayerView) {
            player.delegate = self
        }
        #endif
        
        func setupAVPlayerCallbacks(_ player: AVPlayer, vc: UIViewController) {
            let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
            timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self else { return }
                self.parent.currentTime = time.seconds
                if let dur = player.currentItem?.duration.seconds, !dur.isNaN && dur > 0 {
                    self.parent.duration = dur
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { [weak self] _ in
                self?.parent.onPlaybackEnded()
            }
        }
        
        deinit {
            if let token = timeObserverToken, let avPlayer = avPlayer {
                avPlayer.removeTimeObserver(token)
            }
        }
    }
}

#if canImport(KSPlayer)
extension KSVideoPlayerRepresentable.Coordinator: PlayerViewDelegate {
    public func player(player: PlayerView, state: PlayerState) {
        DispatchQueue.main.async {
            switch state {
            case .playing:
                self.parent.isPlaying = true
                self.parent.isBuffering = false
            case .paused:
                self.parent.isPlaying = false
                self.parent.isBuffering = false
            case .buffering:
                self.parent.isBuffering = true
            case .playedToTheEnd:
                self.parent.onPlaybackEnded()
            default:
                break
            }
        }
    }
    
    public func player(player: PlayerView, currentTime: TimeInterval, totalTime: TimeInterval) {
        DispatchQueue.main.async {
            self.parent.currentTime = currentTime
            if totalTime > 0 {
                self.parent.duration = totalTime
            }
        }
    }
    
    public func player(player: PlayerView, finish error: Error?) {
        if let err = error {
            print("[KSPlayer] 播放遇到错误: \(err.localizedDescription)")
        }
    }
}
#endif
