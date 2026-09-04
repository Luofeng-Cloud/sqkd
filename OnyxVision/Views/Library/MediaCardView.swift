import SwiftUI

public struct MediaCardView: View {
    public let item: EmbyItem
    public let server: EmbyServer
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // 海报封面
                AsyncImage(url: item.posterUrl(serverUrl: server.url, apiKey: server.token)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(white: 0.15))
                            .overlay(ProgressView().tint(.gray))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color(white: 0.2))
                            .overlay(
                                Image(systemName: "film")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .aspectRatio(2/3, contentMode: .fit)
                .cornerRadius(10)
                .clipped()
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                
                // 杜比视界金黄色原画角标
                if item.isDolbyVision {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 8, weight: .black))
                        Text(item.dolbyVisionBadge ?? "DV")
                            .font(.system(size: 9, weight: .black))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.6, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.black)
                    .cornerRadius(5)
                    .padding(6)
                    .shadow(color: .black.opacity(0.5), radius: 3)
                }
                
                // 底部播放进度条
                if let progress = item.userData?.playbackPositionSeconds,
                   let total = item.runTimeTicks, total > 0 {
                    let fraction = min(1.0, max(0.0, progress / item.durationSeconds))
                    if fraction > 0.02 && fraction < 0.95 {
                        VStack {
                            Spacer()
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(height: 4)
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: geo.size.width * fraction, height: 4)
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                }
            }
            
            // 标题与年份
            Text(item.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            HStack(spacing: 4) {
                if let year = item.productionYear {
                    Text("\(year)")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                if let rating = item.communityRating {
                    Spacer()
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
