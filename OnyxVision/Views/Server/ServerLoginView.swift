import SwiftUI

public struct ServerLoginView: View {
    @Binding public var currentServer: EmbyServer?
    
    @State private var serverUrl: String = "https://link01.okemby.org:8443"
    @State private var username: String = "LuoFeng"
    @State private var password: String = "nnl7Yo16"
    @State private var rememberLogin: Bool = true
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    public var body: some View {
        ZStack {
            Color(white: 0.05).ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // MARK: Logo 与标题
                VStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.98, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.55, blue: 0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.yellow.opacity(0.3), radius: 12)
                        
                        Image(systemName: "sparkles.tv.fill")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.black)
                    }
                    
                    Text("EmbyVision")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Text("原画直出")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                        
                        Text("原生杜比视界 (Dolby Vision)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .foregroundColor(.yellow)
                            .cornerRadius(4)
                    }
                }
                
                // MARK: 表单输入卡片
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("服务器地址 (包含 http:// 或 https://)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("如 https://emby.myserver.com:8096", text: $serverUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("用户名")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Emby 用户名", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("密码")
                            .font(.caption)
                            .foregroundColor(.gray)
                        SecureField("密码 (无密码可留空)", text: $password)
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    
                    Toggle("自动记住登录状态", isOn: $rememberLogin)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .tint(.yellow)
                        .padding(.top, 4)
                }
                .padding(20)
                .background(Color(white: 0.1))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // MARK: 登录按钮
                Button(action: handleLogin) {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.black)
                        } else {
                            Text("连接并进入媒体库")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.55, blue: 0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.yellow.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .disabled(isLoading || serverUrl.isEmpty || username.isEmpty)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .onAppear {
            loadSavedCredentials()
        }
    }
    
    private func handleLogin() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let authResponse = try await EmbyAPIService.shared.authenticate(
                    serverUrl: serverUrl,
                    username: username,
                    password: password
                )
                
                let server = EmbyServer(
                    url: serverUrl,
                    name: "我的 Emby 库",
                    username: username,
                    token: authResponse.accessToken,
                    userId: authResponse.user.id
                )
                
                await MainActor.run {
                    if rememberLogin {
                        saveCredentials(server: server)
                    }
                    self.currentServer = server
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveCredentials(server: EmbyServer) {
        UserDefaults.standard.set(server.url, forKey: "saved_server_url")
        UserDefaults.standard.set(server.username, forKey: "saved_username")
        UserDefaults.standard.set(password, forKey: "saved_password")
        UserDefaults.standard.set(server.token, forKey: "saved_token")
        UserDefaults.standard.set(server.userId, forKey: "saved_user_id")
        UserDefaults.standard.set(true, forKey: "saved_remember")
    }
    
    private func loadSavedCredentials() {
        if UserDefaults.standard.bool(forKey: "saved_remember") {
            if let url = UserDefaults.standard.string(forKey: "saved_server_url") {
                self.serverUrl = url
            }
            if let user = UserDefaults.standard.string(forKey: "saved_username") {
                self.username = user
            }
            if let pwd = UserDefaults.standard.string(forKey: "saved_password") {
                self.password = pwd
            }
        }
    }
}
