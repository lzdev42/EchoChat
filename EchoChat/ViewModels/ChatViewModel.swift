import Foundation
import SwiftUI
import SwiftData

// MARK: - 聊天视图模型
@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var canSend: Bool = false
    @Published var canRegenerate: Bool = false
    
    // MARK: - Session State
    private var currentSession: ChatSession?
    weak var mainViewModel: MainViewModel?
    var modelContext: ModelContext? { mainViewModel?.modelContext }
    
    // MARK: - Initialization
    init(mainViewModel: MainViewModel? = nil) {
        self.mainViewModel = mainViewModel
        setupCanSendObserver()
    }
    
    // MARK: - Session Management
    func setCurrentSession(_ session: ChatSession) {
        if currentSession?.id != session.id {
            currentSession = session
            loadMessages(for: session)
        }
        updateCanRegenerate()
    }
    
    // MARK: - Message Management
    func sendMessage() {
        guard canSend, let context = modelContext else { return }
        
        // 如果没有当前会话，创建一个新会话
        let session = currentSession ?? createNewSessionForChat()
        
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // 创建用户消息
        let userMessage = ChatMessage(
            content: trimmedText,
            sender: .user,
            session: session
        )
        
        // 添加用户消息到列表和数据库
        context.insert(userMessage)
        session.messages.append(userMessage)
        messages.append(userMessage)
        
        // 清空输入框
        inputText = ""
        
        // 创建临时的助手消息（显示加载状态）
        let assistantMessage = ChatMessage(
            content: "",
            sender: .assistant,
            status: .sending,
            session: session
        )
        
        context.insert(assistantMessage)
        session.messages.append(assistantMessage)
        messages.append(assistantMessage)
        isLoading = true
        
        // 更新会话时间戳
        updateSessionTimestamp()
        
        // 保存到数据库
        saveMessages()
        
        // TODO: 调用聊天服务发送消息
        // 这里预留给您后续开发
        simulateResponse(for: assistantMessage.id)
    }
    
    func regenerateLastResponse() {
        guard canRegenerate,
              currentSession != nil,
              let lastAssistantIndex = messages.lastIndex(where: { $0.sender == .assistant }) else {
            return
        }
        
        // 更新最后一条助手消息状态
        messages[lastAssistantIndex].status = .regenerating
        messages[lastAssistantIndex].content = ""
        isLoading = true
        
        // 保存状态变化
        saveMessages()
        
        // TODO: 调用聊天服务重新生成响应
        // 这里预留给您后续开发
        simulateResponse(for: messages[lastAssistantIndex].id)
    }
    
    func deleteMessage(_ message: ChatMessage) {
        messages.removeAll { $0.id == message.id }
        saveMessages()
        updateCanRegenerate()
    }
    
    func resendMessage(_ message: ChatMessage) {
        guard message.sender == .user else { return }

        inputText = message.content
        sendMessage()
    }

    // MARK: - Message Editing
    func startEditingMessage(_ message: ChatMessage) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        messages[index].startEditing()
        updateCanRegenerate()
    }

    func saveEditedMessage(_ message: ChatMessage, newContent: String) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }

        let trimmedContent = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        messages[index].content = trimmedContent
        messages[index].finishEditing()

        saveMessages()
        updateCanRegenerate()
    }

    func cancelEditingMessage(_ message: ChatMessage) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        messages[index].cancelEditing()
        updateCanRegenerate()
    }

    // MARK: - Input Management
    func updateInputText(_ text: String) {
        inputText = text
    }
    
    func clearInput() {
        inputText = ""
    }
    
    // MARK: - Attachment Management
    func addImage() {
        // TODO: 实现图片选择和添加
        // 预留给您后续开发
    }
    
    func addFile() {
        // TODO: 实现文件选择和添加
        // 预留给您后续开发
    }
    
    // MARK: - Private Methods
    private func setupCanSendObserver() {
        // 监听输入文本变化，更新发送按钮状态
        $inputText
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !self.isLoading }
            .assign(to: &$canSend)
        
        $isLoading
            .map { !$0 && !self.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .assign(to: &$canSend)
    }
    
    private func updateCanRegenerate() {
        canRegenerate = !isLoading && 
                       !messages.isEmpty && 
                       messages.last?.sender == .assistant &&
                       messages.last?.status != .sending &&
                       messages.last?.status != .regenerating
    }
    
    private func loadMessages(for session: ChatSession) {
        // 直接使用 SwiftData 关系加载消息
        messages = session.messages.sorted { $0.timestamp < $1.timestamp }
        updateCanRegenerate()
    }
    
    private func saveMessages() {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
            print("保存消息失败: \(error)")
        }
    }
    
    private func updateSessionTimestamp() {
        guard let session = currentSession else { return }
        
        session.updateTimestamp()
        saveMessages()
    }
    
    // MARK: - Session Management
    private func createNewSessionForChat() -> ChatSession {
        guard let context = modelContext,
              let mainViewModel = mainViewModel else {
            fatalError("无法创建会话：缺少 ModelContext 或 MainViewModel")
        }
        
        let newSession = ChatSession(
            title: "新对话",
            selectedModel: mainViewModel.settings.selectedModelId,
            isActive: true
        )
        
        // 设置其他会话为非活跃状态
        for session in mainViewModel.sessions {
            session.isActive = false
        }
        
        // 插入到 SwiftData
        context.insert(newSession)
        
        // 更新 MainViewModel
        mainViewModel.sessions.insert(newSession, at: 0)
        mainViewModel.currentSession = newSession
        mainViewModel.selectedSidebarItem = newSession.id
        mainViewModel.isReadyForNewChat = false // 重置新对话准备状态
        
        // 设置为当前会话
        currentSession = newSession
        
        // 保存更改
        try? context.save()
        
        return newSession
    }
    
    // MARK: - Simulation (临时用于演示)
    private func simulateResponse(for messageId: UUID) {
        Task {
            // 模拟网络延迟
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
            
            guard let messageIndex = messages.firstIndex(where: { $0.id == messageId }) else {
                return
            }
            
            // 更新消息内容和状态
            messages[messageIndex].content = "这是一个模拟的AI响应。您需要实现真正的聊天服务来替换这个模拟响应。"
            messages[messageIndex].status = .sent
            
            isLoading = false
            updateCanRegenerate()
            saveMessages()
            updateSessionTimestamp()
        }
    }
    
    private func createSampleMessages(for session: ChatSession) -> [ChatMessage] {
        guard let context = modelContext else { return [] }
        
        let now = Date()
        let calendar = Calendar.current
        
        let userMessage = ChatMessage(
            content: "你好！我想学习SwiftUI，有什么建议吗？",
            sender: .user,
            timestamp: calendar.date(byAdding: .minute, value: -10, to: now) ?? now,
            session: session
        )
        
        let assistantMessage = ChatMessage(
            content: "很高兴你想学习SwiftUI！SwiftUI是苹果的声明式UI框架，它让创建用户界面变得更加直观和高效。\n\n建议你从以下几个方面开始：\n\n1. **基础概念**：了解声明式编程的思想\n2. **基本组件**：学习Text、Button、Image等基础视图\n3. **布局系统**：掌握VStack、HStack、ZStack的使用\n4. **状态管理**：理解@State、@Binding等属性包装器\n\n你现在的SwiftUI基础如何？",
            sender: .assistant,
            timestamp: calendar.date(byAdding: .minute, value: -9, to: now) ?? now,
            session: session
        )
        
        context.insert(userMessage)
        context.insert(assistantMessage)
        session.messages.append(contentsOf: [userMessage, assistantMessage])
        
        try? context.save()
        
        return [userMessage, assistantMessage]
    }
}
