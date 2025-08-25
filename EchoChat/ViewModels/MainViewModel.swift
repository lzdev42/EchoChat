import Foundation
import SwiftUI
import SwiftData

// MARK: - 主界面视图模型
@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var sessions: [ChatSession] = []
    @Published var currentSession: ChatSession?
    @Published var settings: AppSettings = AppSettings()
    @Published var isHistoryPresented: Bool = false
    @Published var isSettingsPresented: Bool = false
    @Published var isModelSelectorPresented: Bool = false
    
    // MARK: - Navigation State
    @Published var selectedSidebarItem: ChatSession.ID?
    @Published var showingSidebar: Bool = true
    @Published var isReadyForNewChat: Bool = false // 标识用户准备开始新对话
    
    // MARK: - SwiftData Context
    var modelContext: ModelContext?
    
    // MARK: - Initialization
    init() {
        loadSettings()
        loadSessions()
        createNewSessionIfNeeded()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        // 重置当前会话，因为我们要重新加载数据
        currentSession = nil
        selectedSidebarItem = nil
        loadSessions() // 重新加载数据
        cleanupAllEmptySessions() // 清理启动时遗留的空会话
        createNewSessionIfNeeded() // 如果有历史会话，选中最新的
    }
    
    // MARK: - Session Management
    func createNewSession() {
        guard let context = modelContext else { return }
        
        // 在创建新会话前，清理当前的空会话
        cleanupEmptySession()
        
        let newSession = ChatSession(
            title: "新对话",
            selectedModel: settings.selectedModelId,
            isActive: true
        )
        
        // 设置其他会话为非活跃状态
        for session in sessions {
            session.isActive = false
        }
        
        context.insert(newSession)
        sessions.insert(newSession, at: 0)
        currentSession = newSession
        selectedSidebarItem = newSession.id
        saveSessions()
    }
    
    func selectSession(_ session: ChatSession) {
        // 在切换会话前，清理当前的空会话
        cleanupEmptySession()
        
        // 更新当前会话状态
        for s in sessions {
            s.isActive = (s.id == session.id)
        }
        
        currentSession = session
        selectedSidebarItem = session.id
        saveSessions()
    }
    
    func deleteSession(_ session: ChatSession) {
        guard let context = modelContext else { return }
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        
        context.delete(session)
        sessions.remove(at: index)
        
        // 如果删除的是当前会话，选择下一个会话或创建新会话
        if currentSession?.id == session.id {
            if !sessions.isEmpty {
                selectSession(sessions[0])
            } else {
                createNewSession()
            }
        }
        
        saveSessions()
    }
    
    func updateSessionTitle(_ session: ChatSession, title: String) {
        session.updateTitle(title)
        
        if currentSession?.id == session.id {
            currentSession = session
        }
        
        saveSessions()
    }
    
    // MARK: - Model Selection
    func selectModel(_ modelId: String) {
        settings.updateSelectedModel(modelId)
        
        // 更新当前会话的模型
        if let session = currentSession {
            session.selectedModel = modelId
            currentSession = session
        }
        
        saveSettings()
        saveSessions()
    }
    
    // MARK: - Navigation Actions
    func showHistory() {
        isHistoryPresented = true
    }
    
    func showSettings() {
        isSettingsPresented = true
    }
    
    func showModelSelector() {
        isModelSelectorPresented = true
    }
    
    func toggleSidebar() {
        showingSidebar.toggle()
    }
    
    func prepareForNewChat() {
        // 在准备新对话前，清理当前的空会话
        cleanupEmptySession()
        
        // 设置准备新对话状态，但不立即创建会话
        currentSession = nil
        selectedSidebarItem = nil
        isReadyForNewChat = true
    }
    
    // MARK: - Private Methods
    private func createNewSessionIfNeeded() {
        // 如果有历史会话，自动选中最新的会话（sessions已按updatedAt倒序排列）
        if !sessions.isEmpty && currentSession == nil {
            selectSession(sessions[0])
        }
        // 如果没有历史会话，不创建新会话，等待用户发起对话时再创建
    }
    
    // MARK: - Empty Session Cleanup
    private func cleanupEmptySession() {
        guard let current = currentSession,
              current.messages.isEmpty,
              modelContext != nil else { return }
        
        // 删除当前空会话
        deleteSessionSilently(current)
    }
    
    private func cleanupAllEmptySessions() {
        guard modelContext != nil else { return }
        
        let emptySessions = sessions.filter { $0.messages.isEmpty }
        for session in emptySessions {
            deleteSessionSilently(session)
        }
    }
    
    private func deleteSessionSilently(_ session: ChatSession) {
        guard let context = modelContext,
              let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        
        // 从 SwiftData 删除
        context.delete(session)
        
        // 从本地数组删除
        sessions.remove(at: index)
        
        // 如果删除的是当前会话，清空当前会话
        if currentSession?.id == session.id {
            currentSession = nil
            selectedSidebarItem = nil
        }
        
        // 保存更改
        do {
            try context.save()
        } catch {
            print("删除空会话失败: \(error)")
        }
    }
    
    private func loadSessions() {
        guard let context = modelContext else {
            // 如果还没有 context，使用示例数据
            sessions = createSampleSessions()
            return
        }
        
        do {
            let descriptor = FetchDescriptor<ChatSession>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            sessions = try context.fetch(descriptor)
        } catch {
            print("加载会话失败: \(error)")
            sessions = []
        }
    }
    
    private func saveSessions() {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
            print("保存会话失败: \(error)")
        }
    }
    
    func loadSettings() {
        Task {
            do {
                let storageService = try StorageServiceFactory.createService()
                if let loadedSettings = try await storageService.loadSettings() {
                    await MainActor.run {
                        settings = loadedSettings
                    }
                } else {
                    // 使用默认设置
                    await MainActor.run {
                        settings = AppSettings()
                    }
                }
            } catch {
                print("加载设置失败: \(error)")
                await MainActor.run {
                    settings = AppSettings()
                }
            }
        }
    }

    func saveSettings() {
        Task {
            do {
                let storageService = try StorageServiceFactory.createService()
                try await storageService.saveSettings(settings)
            } catch {
                print("保存设置失败: \(error)")
            }
        }
    }
    
    private func createSampleSessions() -> [ChatSession] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            ChatSession(
                title: "Swift编程问题",
                createdAt: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
                updatedAt: calendar.date(byAdding: .minute, value: -10, to: now) ?? now,
                selectedModel: "gpt-4",
                isActive: true
            ),
            ChatSession(
                title: "iOS开发最佳实践",
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                updatedAt: calendar.date(byAdding: .hour, value: -3, to: now) ?? now,
                selectedModel: "claude-3-opus"
            ),
            ChatSession(
                title: "SwiftUI布局问题",
                createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                updatedAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                selectedModel: "gpt-3.5-turbo"
            )
        ]
    }
}
