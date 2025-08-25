import Foundation

// MARK: - 聊天服务协议
protocol ChatServiceProtocol {
    func sendMessage(_ message: ChatMessage, to session: ChatSession) async throws -> ChatMessage
    func regenerateMessage(_ message: ChatMessage, in session: ChatSession) async throws -> ChatMessage
    func streamMessage(_ message: ChatMessage, to session: ChatSession) -> AsyncThrowingStream<String, Error>
}

// MARK: - 聊天服务错误
enum ChatServiceError: LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case rateLimitExceeded
    case modelNotAvailable
    case invalidRequest
    case serverError(Int)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API密钥无效或未设置"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .rateLimitExceeded:
            return "请求频率超限，请稍后再试"
        case .modelNotAvailable:
            return "所选模型当前不可用"
        case .invalidRequest:
            return "请求格式无效"
        case .serverError(let code):
            return "服务器错误 (代码: \(code))"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}

// MARK: - 聊天服务实现
class ChatService: ChatServiceProtocol {
    private let settings: AppSettings
    
    init(settings: AppSettings) {
        self.settings = settings
    }
    
    func sendMessage(_ message: ChatMessage, to session: ChatSession) async throws -> ChatMessage {
        // TODO: 实现真正的聊天服务
        // 这里预留给您后续开发
        
        // 模拟实现
        return try await simulateResponse(for: message, in: session)
    }
    
    func regenerateMessage(_ message: ChatMessage, in session: ChatSession) async throws -> ChatMessage {
        // TODO: 实现消息重新生成
        // 这里预留给您后续开发
        
        // 模拟实现
        return try await simulateResponse(for: message, in: session)
    }
    
    func streamMessage(_ message: ChatMessage, to session: ChatSession) -> AsyncThrowingStream<String, Error> {
        // TODO: 实现流式响应
        // 这里预留给您后续开发
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await simulateResponse(for: message, in: session)
                    
                    // 模拟流式输出
                    let words = response.content.components(separatedBy: " ")
                    for (index, word) in words.enumerated() {
                        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                        
                        if index == words.count - 1 {
                            continuation.yield(word)
                        } else {
                            continuation.yield(word + " ")
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func simulateResponse(for message: ChatMessage, in session: ChatSession) async throws -> ChatMessage {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
        
        // 根据用户消息生成模拟响应
        let responseContent = generateSimulatedResponse(for: message.content, model: session.selectedModel)
        
        return ChatMessage(
            content: responseContent,
            sender: .assistant,
            session: session
        )
    }
    
    private func generateSimulatedResponse(for userMessage: String, model: String) -> String {
        let responses = [
            "这是来自 \(model) 的模拟响应。您需要实现真正的聊天服务来替换这个模拟功能。",
            "我理解您的问题。这里是一个详细的回答...\n\n（注意：这是模拟响应，需要您实现真正的API调用）",
            "根据您的问题，我建议...\n\n1. 首先分析问题\n2. 然后制定解决方案\n3. 最后验证结果\n\n（模拟响应）",
            "让我来帮您解决这个问题。\n\n基于 \(model) 模型的分析，我认为...\n\n（这是演示数据）"
        ]
        
        return responses.randomElement() ?? responses[0]
    }
}

// MARK: - 工厂类
class ChatServiceFactory {
    static func createService(for settings: AppSettings) -> ChatServiceProtocol {
        return ChatService(settings: settings)
    }
}
