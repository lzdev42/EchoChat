import Foundation

// MARK: - AI模型配置
struct ModelConfig: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let displayName: String
    let provider: String
    let maxTokens: Int
    let supportsImages: Bool
    let supportsFiles: Bool
    var isEnabled: Bool
    
    init(
        id: String,
        name: String,
        displayName: String,
        provider: String,
        maxTokens: Int,
        supportsImages: Bool = false,
        supportsFiles: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.provider = provider
        self.maxTokens = maxTokens
        self.supportsImages = supportsImages
        self.supportsFiles = supportsFiles
        self.isEnabled = isEnabled
    }
}

// MARK: - 预定义模型
extension ModelConfig {
    static let defaultModels: [ModelConfig] = [
        ModelConfig(
            id: "gpt-4",
            name: "gpt-4",
            displayName: "GPT-4",
            provider: "OpenAI",
            maxTokens: 8192,
            supportsImages: true,
            supportsFiles: true
        ),
        ModelConfig(
            id: "gpt-3.5-turbo",
            name: "gpt-3.5-turbo",
            displayName: "GPT-3.5 Turbo",
            provider: "OpenAI",
            maxTokens: 4096
        ),
        ModelConfig(
            id: "claude-3-opus",
            name: "claude-3-opus-20240229",
            displayName: "Claude 3 Opus",
            provider: "Anthropic",
            maxTokens: 200000,
            supportsImages: true,
            supportsFiles: true
        ),
        ModelConfig(
            id: "claude-3-sonnet",
            name: "claude-3-sonnet-20240229",
            displayName: "Claude 3 Sonnet",
            provider: "Anthropic",
            maxTokens: 200000,
            supportsImages: true,
            supportsFiles: true
        ),
        ModelConfig(
            id: "gemini-1.5-pro",
            name: "gemini-1.5-pro-latest",
            displayName: "Gemini 1.5 Pro",
            provider: "Google",
            maxTokens: 1000000,
            supportsImages: true,
            supportsFiles: true
        ),
        ModelConfig(
            id: "gemini-1.5-flash",
            name: "gemini-1.5-flash-latest", 
            displayName: "Gemini 1.5 Flash",
            provider: "Google",
            maxTokens: 1000000,
            supportsImages: true,
            supportsFiles: true
        )
    ]
    
    static var defaultModel: ModelConfig {
        return defaultModels.first(where: { $0.id == "gpt-4" }) ?? defaultModels[0]
    }
}
