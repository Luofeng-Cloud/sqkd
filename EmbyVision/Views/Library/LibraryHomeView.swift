import SwiftUI

public struct LibraryHomeView: View {
    public let server: EmbyServer
    public let onLogout: () -> Void
    
    @State private var views: [EmbyItem] = []
    @State private var selectedViewId: String? = nil
    
    @State private var resumeItems: [EmbyItem] = []
    @State private var mediaItems: [EmbyItem] = []
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var searchText = ""
    @State private var showSettings = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 14)
    ]
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.06).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // MARK: 搜索栏
                        searchBar
                        
                        // MARK: 媒体库视图切换标签栏
                        librarySelectorBar
                        
                        // MARK: 继续观看横向卡片区
                        if !resumeItems.isEmpty && searchText.isEmpty {
                            resumeSection
                        }
                        
                        // MARK: 海报墙网格
                        mediaGridSection
                    }
                    .padding(.vertical, 16)
                }
                .refreshable {
                    await loadAllData()
                }
                
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(1.3)
                }
            }
            .navigationTitle(server.name.isEmpty ? "Emby 媒体库" : server.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(server: server, onLogout: onLogout)
            }
            .task {
                await loadAllData()
            }
        }
    }
    
    // MARK: - 搜索输入框
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("搜索电影、剧集、演员...", text: $searchText)
                .foregroundColor(.white)
                .submitLabel(.search)
                .onSubmit {
                    Task { await loadItems() }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    Task { await loadItems() }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
    
    // MARK: - 媒体库水平切换栏
    private var librarySelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button(action: {
                    selectedViewId = nil
                    Task { await loadItems() }
                }) {
                    Text("全部")
                        .font(.system(size: 14, weight: selectedViewId == nil ? .bold : .regular))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(selectedViewId == nil ? Color.white : Color.white.opacity(0.1))
                        .foregroundColor(selectedViewId == nil ? .black : .white)
                        .cornerRadius(16)
                }
                
                ForEach(views) { v in
                    Button(action: {
                        selectedViewId = v.id
                        Task { await loadItems() }
                    }) {
                        Text(v.name)
                            .font(.system(size: 14, weight: selectedViewId == v.id ? .bold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(selectedViewId == v.id ? Color.white : Color.white.opacity(0.1))
                            .foregroundColor(selectedViewId == v.id ? .black : .white)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 继续观看横向卡片
    private var resumeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("继续观看")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(resumeItems) { item in
                        NavigationLink(destination: MediaDetailView(item: item, server: server)) {
                            MediaCardView(item: item, server: server)
                                .frame(width: 120)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - 海报墙网格区
    private var mediaGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(searchText.isEmpty ? "媒体列表" : "搜索结果")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(mediaItems) { item in
                    NavigationLink(destination: MediaDetailView(item: item, server: server)) {
                        MediaCardView(item: item, server: server)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func loadAllData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let fetchViews = EmbyAPIService.shared.getViews(server: server)
            async let fetchResume = EmbyAPIService.shared.getResumeItems(server: server)
            
            let (loadedViews, loadedResume) = try await (fetchViews, fetchResume)
            await MainActor.run {
                self.views = loadedViews
                self.resumeItems = loadedResume
            }
            
            await loadItems()
        } catch {
            print("加载数据失败: \(error.localizedDescription)")
        }
    }
    
    private func loadItems() async {
        do {
            let items = try await EmbyAPIService.shared.getItems(
                server: server,
                parentId: selectedViewId,
                searchTerm: searchText.isEmpty ? nil : searchText
            )
            await MainActor.run {
                self.mediaItems = items
            }
        } catch {
            print("加载项目列表失败: \(error.localizedDescription)")
        }
    }
}
