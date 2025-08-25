import Foundation

// MARK: - AI API 请求和响应模型

/// 聊天消息角色
enum ChatRole: String, Codable {
    case system = "system"
    case user = "user"
    case assistant = "assistant"
}

/// 聊天消息
struct ChatAPIMessage: Codable {
    let role: ChatRole
    let content: String
}

/// 聊天请求
struct ChatRequest: Codable {
    let model: String
    let messages: [ChatAPIMessage]
    let max_tokens: Int?
    let temperature: Double?
    let stream: Bool?
    
    init(
        model: String,
        messages: [ChatAPIMessage],
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        stream: Bool? = false
    ) {
        self.model = model
        self.messages = messages
        self.max_tokens = maxTokens
        self.temperature = temperature
        self.stream = stream
    }
}

/// 聊天响应中的选择项
struct ChatChoice: Codable {
    let index: Int
    let message: ChatAPIMessage
    let finish_reason: String?
}

/// 聊天响应中的使用统计
struct ChatUsage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

/// 聊天响应
struct ChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [ChatChoice]
    let usage: ChatUsage?
}

/// 模型信息
struct AIModel: Codable, Identifiable {
    let id: String
    let object: String
    let created: Int?
    let owned_by: String?
}

/// 模型列表响应
struct ModelsResponse: Codable {
    let object: String
    let data: [AIModel]
}

// MARK: - 工具函数
extension AIModel {
    /// 从模型ID推导provider
    static func generateProvider(from id: String) -> String {
        if id.contains("gpt") {
            return "OpenAI"
        } else if id.contains("gemini") {
            return "Google"
        }
        return "Unknown"
    }
}

/// API 测试结果
struct APITestResult {
    let isValid: Bool
    let error: String?
    let models: [AIModel]?
    
    static func success(models: [AIModel]) -> APITestResult {
        return APITestResult(isValid: true, error: nil, models: models)
    }
    
    static func failure(error: String) -> APITestResult {
        return APITestResult(isValid: false, error: error, models: nil)
    }
}

// MARK: - AI API 错误
enum AIAPIError: Error, LocalizedError {
    case missingAPIKey
    case invalidModel
    case invalidResponse
    case quotaExceeded
    case rateLimited
    case unauthorized
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "缺少 API 密钥"
        case .invalidModel:
            return "无效的模型"
        case .invalidResponse:
            return "无效的响应格式"
        case .quotaExceeded:
            return "API 配额已用完"
        case .rateLimited:
            return "请求频率过高，请稍后再试"
        case .unauthorized:
            return "API 密钥无效或无权限"
        case .serverError(let message):
            return "服务器错误: \(message)"
        }
    }
}

// MARK: - AI API 客户端
class AIAPIClient {
    
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient = HTTPClient()) {
        self.httpClient = httpClient
    }
    
    /// 发送聊天请求
    /// - Parameters:
    ///   - baseURL: API 基础 URL
    ///   - apiKey: API 密钥
    ///   - request: 聊天请求
    /// - Returns: 聊天响应
    func sendChatRequest(
        baseURL: String,
        apiKey: String,
        request: ChatRequest
    ) async throws -> ChatResponse {
        
        guard !apiKey.isEmpty else {
            throw AIAPIError.missingAPIKey
        }
        
        // 构建完整 URL
        let fullURL = baseURL.hasSuffix("/") ? baseURL + "chat/completions" : baseURL + "/chat/completions"
        
        // 构建请求头
        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        
        do {
            let response = try await httpClient.postJSON(
                url: fullURL,
                headers: headers,
                jsonBody: request,
                responseType: ChatResponse.self
            )
            
            return response
            
        } catch let httpError as HTTPError {
            // 将 HTTP 错误转换为更具体的 AI API 错误
            switch httpError {
            case .httpError(401, _):
                throw AIAPIError.unauthorized
            case .httpError(429, _):
                throw AIAPIError.rateLimited
            case .httpError(403, _):
                throw AIAPIError.quotaExceeded
            case .httpError(let code, let message) where code >= 500:
                throw AIAPIError.serverError(message ?? "服务器内部错误")
            default:
                throw httpError
            }
        }
    }
    
    /// 便捷方法：发送简单文本消息
    /// - Parameters:
    ///   - baseURL: API 基础 URL
    ///   - apiKey: API 密钥
    ///   - model: 模型名称
    ///   - message: 用户消息
    ///   - systemPrompt: 系统提示（可选）
    ///   - maxTokens: 最大 token 数（可选）
    ///   - temperature: 温度参数（可选）
    /// - Returns: 助手回复内容
    func sendSimpleMessage(
        baseURL: String,
        apiKey: String,
        model: String,
        message: String,
        systemPrompt: String? = nil,
        maxTokens: Int? = nil,
        temperature: Double? = nil
    ) async throws -> String {
        
        var messages: [ChatAPIMessage] = []
        
        // 添加系统提示
        if let systemPrompt = systemPrompt {
            messages.append(ChatAPIMessage(role: .system, content: systemPrompt))
        }
        
        // 添加用户消息
        messages.append(ChatAPIMessage(role: .user, content: message))
        
        let request = ChatRequest(
            model: model,
            messages: messages,
            maxTokens: maxTokens,
            temperature: temperature
        )
        
        let response = try await sendChatRequest(
            baseURL: baseURL,
            apiKey: apiKey,
            request: request
        )
        
        guard let firstChoice = response.choices.first,
              !firstChoice.message.content.isEmpty else {
            throw AIAPIError.invalidResponse
        }
        
        return firstChoice.message.content
    }
    
    /// 获取可用模型列表
    /// - Parameters:
    ///   - baseURL: API 基础 URL
    ///   - apiKey: API 密钥
    /// - Returns: 模型列表
    func fetchModels(baseURL: String, apiKey: String) async throws -> [AIModel] {
        guard !apiKey.isEmpty else {
            throw AIAPIError.missingAPIKey
        }
        
        // 构建完整 URL
        let fullURL = baseURL.hasSuffix("/") ? baseURL + "models" : baseURL + "/models"
        
        // 构建请求头
        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        
        do {
            let response = try await httpClient.request(
                url: fullURL,
                method: .GET,
                headers: headers,
                responseType: ModelsResponse.self
            )
            
            // 过滤出聊天相关的模型
            let chatModels = response.data.filter { model in
                let id = model.id.lowercased()
                // OpenAI 聊天模型
                if id.contains("gpt") && !id.contains("embedding") && !id.contains("whisper") && !id.contains("tts") && !id.contains("dall-e") {
                    return true
                }
                // Gemini 聊天模型
                if id.contains("gemini") {
                    return true
                }
                return false
            }
            
            return chatModels.sorted { $0.id < $1.id }
            
        } catch let httpError as HTTPError {
            // 将 HTTP 错误转换为更具体的 AI API 错误
            switch httpError {
            case .httpError(401, _):
                throw AIAPIError.unauthorized
            case .httpError(429, _):
                throw AIAPIError.rateLimited
            case .httpError(403, _):
                throw AIAPIError.quotaExceeded
            case .httpError(let code, let message) where code >= 500:
                throw AIAPIError.serverError(message ?? "服务器内部错误")
            default:
                throw httpError
            }
        }
    }
    
    /// 测试 API Key 有效性并获取模型列表
    /// - Parameters:
    ///   - baseURL: API 基础 URL
    ///   - apiKey: API 密钥
    /// - Returns: 测试结果
    func testAPIKey(baseURL: String, apiKey: String) async -> APITestResult {
        do {
            let models = try await fetchModels(baseURL: baseURL, apiKey: apiKey)
            return APITestResult.success(models: models)
        } catch {
            return APITestResult.failure(error: error.localizedDescription)
        }
    }
}
