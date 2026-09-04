import Foundation
import Combine

public class PlaybackSyncManager: ObservableObject {
    public static let shared = PlaybackSyncManager()
    
    private var timer: AnyCancellable?
    private var currentServer: EmbyServer?
    private var currentItemId: String?
    private var playSessionId: String?
    private var currentTicks: Int64 = 0
    private var isPlaying: Bool = false
    
    private init() {}
    
    public func startSession(server: EmbyServer, itemId: String, playSessionId: String?, initialSeconds: Double) {
        self.currentServer = server
        self.currentItemId = itemId
        self.playSessionId = playSessionId ?? UUID().uuidString
        self.currentTicks = Int64(initialSeconds * 10_000_000.0)
        self.isPlaying = true
        
        Task {
            await EmbyAPIService.shared.reportPlaybackStart(
                server: server,
                itemId: itemId,
                playSessionId: self.playSessionId!,
                positionTicks: self.currentTicks
            )
        }
        
        startTimer()
    }
    
    public func updatePosition(seconds: Double, isPaused: Bool) {
        self.currentTicks = Int64(seconds * 10_000_000.0)
        self.isPlaying = !isPaused
    }
    
    public func stopSession() {
        timer?.cancel()
        timer = nil
        
        guard let server = currentServer, let itemId = currentItemId, let session = playSessionId else {
            return
        }
        
        let finalTicks = currentTicks
        Task {
            await EmbyAPIService.shared.reportPlaybackStopped(
                server: server,
                itemId: itemId,
                playSessionId: session,
                positionTicks: finalTicks
            )
        }
        
        self.currentServer = nil
        self.currentItemId = nil
        self.playSessionId = nil
    }
    
    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                      let server = self.currentServer,
                      let itemId = self.currentItemId,
                      let session = self.playSessionId else { return }
                
                let ticks = self.currentTicks
                let paused = !self.isPlaying
                
                Task {
                    await EmbyAPIService.shared.reportPlaybackProgress(
                        server: server,
                        itemId: itemId,
                        playSessionId: session,
                        positionTicks: ticks,
                        isPaused: paused
                    )
                }
            }
    }
}
