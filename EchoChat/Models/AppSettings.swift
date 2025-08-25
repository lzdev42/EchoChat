import Foundation

// MARK: - 前向声明
// 注意：这里需要确保 AIModel 在其他文件中已定义
// 或者我们可以创建一个协议来解决循环依赖

// MARK: - 动态获取的模型
struct FetchedModel: Codable, Identifiable, Equatable {
    let id: String
    let displayName: String
    let provider: String
    let created: Int?
    let owned_by: String?
    
    init(id: String, displayName: String, provider: String, created: Int? = nil, owned_by: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.provider = provider
        self.created = created
        self.owned_by = owned_by
    }
}

// MARK: - 应用设置模型
struct AppSettings: Codable, Equatable {
    var selectedModelId: String
    var fontSize: Double
    var enabledModels: Set<String>
    var autoSaveChats: Bool
    var showTimestamps: Bool
    var compactMode: Bool
    
    // API相关设置
    var apiKeys: [String: String] // provider -> apiKey
    var customEndpoints: [String: String] // provider -> endpoint
    
    // 动态获取的模型列表
    var fetchedModels: [String: [FetchedModel]] // provider -> models
    
    init(
        selectedModelId: String = "gpt-4",
        fontSize: Double = 14.0,
        enabledModels: Set<String> = Set(ModelConfig.defaultModels.map { $0.id }),
        autoSaveChats: Bool = true,
        showTimestamps: Bool = false,
        compactMode: Bool = false,
        apiKeys: [String: String] = [:],
        customEndpoints: [String: String] = [:],
        fetchedModels: [String: [FetchedModel]] = [:]
    ) {
        self.selectedModelId = selectedModelId
        self.fontSize = fontSize
        self.enabledModels = enabledModels
        self.autoSaveChats = autoSaveChats
        self.showTimestamps = showTimestamps
        self.compactMode = compactMode
        self.apiKeys = apiKeys
        self.customEndpoints = customEndpoints
        self.fetchedModels = fetchedModels
    }
}

// MARK: - 便利扩展
extension AppSettings {
    var availableModels: [ModelConfig] {
        var models: [ModelConfig] = []
        
        // 添加默认模型（已启用的）
        models.append(contentsOf: ModelConfig.defaultModels.filter { enabledModels.contains($0.id) })
        
        // 添加动态获取的模型（转换为 ModelConfig）
        for (provider, fetchedModels) in fetchedModels {
            for fetchedModel in fetchedModels where enabledModels.contains(fetchedModel.id) {
                let modelConfig = ModelConfig(
                    id: fetchedModel.id,
                    name: fetchedModel.displayName,
                    displayName: fetchedModel.displayName,
                    provider: fetchedModel.provider,
                    maxTokens: 4096, // 默认值，后续可以优化
                    supportsImages: false, // 默认值，后续可以优化
                    supportsFiles: false, // 默认值，后续可以优化
                    isEnabled: true
                )
                models.append(modelConfig)
            }
        }
        
        return models
    }
    
    var selectedModel: ModelConfig {
        // 首先在默认模型中查找
        if let model = ModelConfig.defaultModels.first(where: { $0.id == selectedModelId }) {
            return model
        }
        
        // 然后在动态获取的模型中查找
        for (_, fetchedModels) in fetchedModels {
            if let fetchedModel = fetchedModels.first(where: { $0.id == selectedModelId }) {
                return ModelConfig(
                    id: fetchedModel.id,
                    name: fetchedModel.displayName,
                    displayName: fetchedModel.displayName,
                    provider: fetchedModel.provider,
                    maxTokens: 4096,
                    supportsImages: false,
                    supportsFiles: false,
                    isEnabled: true
                )
            }
        }
        
        return ModelConfig.defaultModel
    }
    
    mutating func updateSelectedModel(_ modelId: String) {
        if enabledModels.contains(modelId) {
            selectedModelId = modelId
        }
    }
    
    mutating func toggleModel(_ modelId: String) {
        if enabledModels.contains(modelId) {
            enabledModels.remove(modelId)
            // 如果禁用的是当前选中的模型，切换到第一个可用模型
            if selectedModelId == modelId && !enabledModels.isEmpty {
                selectedModelId = enabledModels.first!
            }
        } else {
            enabledModels.insert(modelId)
        }
    }
    
    /// 更新指定提供商的模型列表
    mutating func updateFetchedModels(for provider: String, models: [FetchedModel]) {
        self.fetchedModels[provider] = models
        
        // 自动启用获取到的模型
        for model in models {
            enabledModels.insert(model.id)
        }
    }
    
    /// 获取指定提供商的所有模型（包括默认和动态获取的）
    func getAllModels(for provider: String) -> [ModelConfig] {
        var models: [ModelConfig] = []
        
        // 添加默认模型
        models.append(contentsOf: ModelConfig.defaultModels.filter { $0.provider == provider })
        
        // 添加动态获取的模型
        if let fetchedModels = fetchedModels[provider] {
            for fetchedModel in fetchedModels {
                let modelConfig = ModelConfig(
                    id: fetchedModel.id,
                    name: fetchedModel.displayName,
                    displayName: fetchedModel.displayName,
                    provider: fetchedModel.provider,
                    maxTokens: 4096,
                    supportsImages: false,
                    supportsFiles: false,
                    isEnabled: true
                )
                models.append(modelConfig)
            }
        }
        
        return models
    }
}
