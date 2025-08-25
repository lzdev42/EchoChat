import SwiftUI

// MARK: - 主视图
struct MainView: View {
    @ObservedObject var mainViewModel: MainViewModel
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var historyViewModel = HistoryViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        Group {
            #if os(macOS)
            macOSLayout
            #else
            iOSLayout
            #endif
        }
        .onAppear {
            setupViewModels()
        }
        .sheet(isPresented: $mainViewModel.isHistoryPresented) {
            HistoryView(
                historyViewModel: historyViewModel,
                mainViewModel: mainViewModel
            )
        }
        .sheet(isPresented: $mainViewModel.isSettingsPresented) {
            SettingsView(
                settingsViewModel: settingsViewModel,
                mainViewModel: mainViewModel
            )
        }
        .sheet(isPresented: $mainViewModel.isModelSelectorPresented) {
            ModelSelectorView(mainViewModel: mainViewModel)
        }
    }
    
    // MARK: - macOS 布局
    #if os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView(sidebar: {
            sidebarContent
        }, detail: {
            detailContent
        })
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
    }
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // 侧栏头部
            HStack {
                Text("对话")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: mainViewModel.createNewSession) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
                .help("新建对话")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // 会话列表
            List(selection: $mainViewModel.selectedSidebarItem) {
                ForEach(mainViewModel.sessions) { session in
                    SidebarHistoryItemView(
                        session: session,
                        isSelected: session.id == mainViewModel.currentSession?.id,
                        onTap: { mainViewModel.selectSession(session) },
                        onDelete: { mainViewModel.deleteSession(session) }
                    )
                    .tag(session.id)
                }
            }
            .listStyle(SidebarListStyle())
        }
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: mainViewModel.toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
    }
    #endif
    
    // MARK: - iOS 布局
    #if os(iOS)
    private var iOSLayout: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            TopNavigationBar(
                title: mainViewModel.currentSession?.displayTitle ?? "EchoChat",
                onHistoryTapped: mainViewModel.showHistory,
                onNewChatTapped: mainViewModel.createNewSession,
                onModelSelectorTapped: mainViewModel.showModelSelector,
                onSettingsTapped: mainViewModel.showSettings
            )
            
            // 聊天内容
            detailContent
        }
    }
    #endif
    
    // MARK: - 详情内容
    private var detailContent: some View {
        Group {
            if mainViewModel.currentSession != nil {
                ChatView(
                    chatViewModel: chatViewModel,
                    mainViewModel: mainViewModel
                )
            } else {
                if mainViewModel.isReadyForNewChat {
                    // 显示聊天界面，等待用户输入
                    ChatView(
                        chatViewModel: chatViewModel,
                        mainViewModel: mainViewModel
                    )
                } else {
                    // 显示欢迎界面
                    WelcomeView(onNewChat: mainViewModel.prepareForNewChat)
                }
            }
        }
        #if os(macOS)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                CompactModelSelector(mainViewModel: mainViewModel)
                
                Button("设置", action: mainViewModel.showSettings)
                    .help("打开设置")
            }
        }
        #endif
    }
    
    // MARK: - 欢迎视图
    private var welcomeView: some View {
        WelcomeView(onNewChat: mainViewModel.prepareForNewChat)
    }
    
    // MARK: - 私有方法
    private func setupViewModels() {
        // 设置 ViewModel 之间的关联
        chatViewModel.mainViewModel = mainViewModel
        historyViewModel.mainViewModel = mainViewModel
        settingsViewModel.mainViewModel = mainViewModel
    }
}

// MARK: - 欢迎视图
struct WelcomeView: View {
    let onNewChat: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // 应用图标和标题
            VStack(spacing: 16) {
                Image(systemName: "message.circle.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("EchoChat")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("智能对话助手")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // 特性介绍
            VStack(spacing: 20) {
                FeatureRow(
                    icon: "brain",
                    title: "多模型支持",
                    description: "支持 GPT-4、Claude 等多种 AI 模型"
                )
                
                FeatureRow(
                    icon: "photo",
                    title: "多媒体对话",
                    description: "支持图片和文件上传，丰富对话体验"
                )
                
                FeatureRow(
                    icon: "clock",
                    title: "历史记录",
                    description: "自动保存对话历史，随时回顾"
                )
            }
            
            // 开始按钮
            Button(action: onNewChat) {
                Text("开始新对话")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: 400)
        .padding(40)
    }
}

// MARK: - 特性行
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 预览
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(mainViewModel: MainViewModel())
    }
}
