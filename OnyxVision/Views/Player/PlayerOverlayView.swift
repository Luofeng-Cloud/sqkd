import SwiftUI

public struct PlayerOverlayView: View {
    public let title: String
    public let isDolbyVision: Bool
    public let dvBadgeText: String?
    public let resolutionBadge: String
    
    @Binding public var currentTime: Double
    @Binding public var duration: Double
    @Binding public var isPlaying: Bool
    @Binding public var isBuffering: Bool
    @Binding public var showControls: Bool
    @Binding public var isLocked: Bool
    
    public let audioStreams: [MediaStream]
    public let subtitleStreams: [MediaStream]
    @Binding public var selectedAudioIndex: Int
    @Binding public var selectedSubtitleIndex: Int
    
    public let onDismiss: () -> Void
    public let onSeek: (Double) -> Void
    public let onTogglePlayPause: () -> Void
    public let onSeekBy: (Double) -> Void
    
    @State private var isDraggingSlider = false
    @State private var dragSliderValue: Double = 0.0
    @State private var showAudioSheet = false
    @State private var showSubtitleSheet = false
    
    // 手势调整亮度与音量
    @State private var gestureBrightness: CGFloat = UIScreen.main.brightness
    @State private var showBrightnessHUD = false
    @State private var gestureVolume: CGFloat = 0.5
    @State private var showVolumeHUD = false
    
    public var body: some View {
        ZStack {
            // 背景遮罩手势（点击切换显示/隐藏控制栏）
            Color.black.opacity(showControls ? 0.45 : 0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showControls.toggle()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 15)
                        .onChanged { value in
                            guard !isLocked else { return }
                            let screenWidth = UIScreen.main.bounds.width
                            let translation = -value.translation.height / 250.0
                            
                            // 屏幕左半边调节亮度
                            if value.startLocation.x < screenWidth * 0.5 {
                                let newBrightness = max(0.0, min(1.0, UIScreen.main.brightness + translation * 0.03))
                                UIScreen.main.brightness = newBrightness
                                gestureBrightness = newBrightness
                                showBrightnessHUD = true
                            } else {
                                // 屏幕右半边调节音量提示
                                gestureVolume = max(0.0, min(1.0, gestureVolume + translation * 0.03))
                                showVolumeHUD = true
                            }
                        }
                        .onEnded { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                showBrightnessHUD = false
                                showVolumeHUD = false
                            }
                        }
                )
            
            // 亮度和音量手势浮动 HUD
            if showBrightnessHUD {
                HStack(spacing: 8) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.yellow)
                    ProgressView(value: Double(gestureBrightness))
                        .frame(width: 120)
                        .tint(.yellow)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .transition(.opacity)
            }
            
            if showVolumeHUD {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.white)
                    ProgressView(value: Double(gestureVolume))
                        .frame(width: 120)
                        .tint(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .transition(.opacity)
            }
            
            // 锁定按钮 (始终悬浮于左下角)
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        withAnimation { isLocked.toggle() }
                    }) {
                        Image(systemName: isLocked ? "lock.fill" : "lock.open")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(isLocked ? .yellow : .white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.leading, 24)
                    .padding(.bottom, 24)
                    Spacer()
                }
            }
            
            // 核心控制层（未锁定时显示）
            if showControls && !isLocked {
                VStack(spacing: 0) {
                    // MARK: 顶部控制栏
                    topBar
                    
                    Spacer()
                    
                    // MARK: 中间快进/快退/播放/缓冲状态
                    centerControls
                    
                    Spacer()
                    
                    // MARK: 底部进度条与音轨字幕控制栏
                    bottomBar
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showAudioSheet) {
            audioTrackPickerView
        }
        .sheet(isPresented: $showSubtitleSheet) {
            subtitlePickerView
        }
    }
    
    // MARK: - 顶部导航栏
    private var topBar: some View {
        HStack(spacing: 14) {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    // 杜比视界原生高亮角标
                    if isDolbyVision {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .black))
                            Text(dvBadgeText ?? "DOLBY VISION")
                                .font(.system(size: 10, weight: .heavy))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.8, blue: 0.3), Color(red: 0.8, green: 0.55, blue: 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.black)
                        .cornerRadius(4)
                        .shadow(color: Color.yellow.opacity(0.4), radius: 4, x: 0, y: 0)
                    }
                    
                    if !resolutionBadge.isEmpty {
                        Text(resolutionBadge)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(3)
                    }
                    
                    Text("直链原画 (Direct Play)")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.3))
                        .foregroundColor(.green)
                        .cornerRadius(3)
                }
            }
            
            Spacer()
            
            // 音轨选择按钮
            Button(action: { showAudioSheet = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                    Text("音轨")
                        .font(.footnote)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
            
            // 字幕选择按钮
            Button(action: { showSubtitleSheet = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "captions.bubble.fill")
                    Text("字幕")
                        .font(.footnote)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - 中间播放暂停与快进快退
    private var centerControls: some View {
        HStack(spacing: 48) {
            Button(action: { onSeekBy(-10) }) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
            
            if isBuffering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.6)
                    .frame(width: 60, height: 60)
            } else {
                Button(action: onTogglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                }
            }
            
            Button(action: { onSeekBy(10) }) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - 底部进度条栏
    private var bottomBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                Text(formatTime(isDraggingSlider ? dragSliderValue : currentTime))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.white)
                
                Slider(
                    value: Binding(
                        get: { isDraggingSlider ? dragSliderValue : currentTime },
                        set: { dragSliderValue = $0 }
                    ),
                    in: 0...max(duration, 1.0),
                    onEditingChanged: { editing in
                        isDraggingSlider = editing
                        if !editing {
                            onSeek(dragSliderValue)
                        }
                    }
                )
                .accentColor(isDolbyVision ? .yellow : .blue)
                
                Text(formatTime(duration))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - 音轨选择弹窗
    private var audioTrackPickerView: some View {
        NavigationView {
            List {
                ForEach(Array(audioStreams.enumerated()), id: \.offset) { index, stream in
                    Button(action: {
                        selectedAudioIndex = index
                        showAudioSheet = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stream.displayTitle ?? stream.title ?? "音轨 \(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 6) {
                                    if let codec = stream.codec {
                                        Text(codec.uppercased())
                                            .font(.caption2)
                                            .padding(3)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(3)
                                    }
                                    Text(stream.channelDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if selectedAudioIndex == index {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择音轨")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { showAudioSheet = false }
                }
            }
        }
    }
    
            // MARK: - 字幕选择与微调弹窗
    @State private var subtitleDelaySeconds: Double = 0.0
    
    private var subtitlePickerView: some View {
        NavigationView {
            List {
                Section(header: Text("字幕时间轴微调 (±0.1s 步进)")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("当前偏移: ")
                                .font(.subheadline)
                            Text(String(format: "%+.1f 秒", subtitleDelaySeconds))
                                .font(.headline)
                                .foregroundColor(subtitleDelaySeconds == 0 ? .primary : .blue)
                            Spacer()
                            Button("重置") {
                                subtitleDelaySeconds = 0.0
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(6)
                        }
                        
                        HStack(spacing: 12) {
                            Button("-0.5s") { subtitleDelaySeconds -= 0.5 }
                                .buttonStyle(.bordered)
                            Button("-0.1s") { subtitleDelaySeconds -= 0.1 }
                                .buttonStyle(.borderedProminent)
                            Button("+0.1s") { subtitleDelaySeconds += 0.1 }
                                .buttonStyle(.borderedProminent)
                            Button("+0.5s") { subtitleDelaySeconds += 0.5 }
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                Section(header: Text("字幕轨道")) {
                    Button(action: {
                        selectedSubtitleIndex = -1
                        showSubtitleSheet = false
                    }) {
                        HStack {
                            Text("关闭字幕")
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedSubtitleIndex == -1 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    ForEach(Array(subtitleStreams.enumerated()), id: \.offset) { index, stream in
                        Button(action: {
                            selectedSubtitleIndex = index
                            showSubtitleSheet = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stream.displayTitle ?? stream.title ?? "字幕 \(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 6) {
                                        if let lang = stream.language {
                                            Text(lang)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        if stream.isDefault {
                                            Text("默认")
                                                .font(.caption2)
                                                .padding(2)
                                                .background(Color.blue.opacity(0.2))
                                                .cornerRadius(3)
                                        }
                                    }
                                }
                                Spacer()
                                if selectedSubtitleIndex == index {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("字幕与特效调节")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { showSubtitleSheet = false }
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else { return "00:00" }
        let total = Int(seconds)
        let s = total % 60
        let m = (total / 60) % 60
        let h = total / 3600
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}
