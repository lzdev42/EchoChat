import Foundation
import SwiftUI

// MARK: - API 测试状态
enum APITestStatus: Equatable {
    case idle
    case testing
    case success
    case failed(String)
}

// MARK: - 设置视图模型
@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var settings: AppSettings
    @Published var availableModels: [ModelConfig] = []
    @Published var isDirty: Bool = false
    
    // MARK: - Temporary Settings (用于编辑)
    @Published var tempSettings: AppSettings
    
    // MARK: - API Testing
    @Published var openaiTestStatus: APITestStatus = .idle
    @Published var geminiTestStatus: APITestStatus = .idle
    
    // MARK: - Services
    private let aiAPIClient = AIAPIClient()
    private let configService = ConfigService()
    
    // MARK: - Data Source
    weak var mainViewModel: MainViewModel?
    
    // MARK: - Initialization
    init(mainViewModel: MainViewModel? = nil) {
        self.mainViewModel = mainViewModel
        let initialSettings = mainViewModel?.settings ?? AppSettings()
        self.settings = initialSettings
        self.tempSettings = initialSettings
        self.availableModels = ModelConfig.defaultModels
        
        setupDirtyObserver()
    }
    
    // MARK: - Settings Management
    func loadSettings() {
        // 尝试从存储服务加载设置
        Task {
            do {
                let storageService = try StorageServiceFactory.createService()
                if let loadedSettings = try await storageService.loadSettings() {
                    await MainActor.run {
                        settings = loadedSettings
                        tempSettings = loadedSettings
                        mainViewModel?.settings = loadedSettings
                        isDirty = false
                    }
                } else {
                    // 如果没有保存的设置，使用 MainViewModel 中的设置
                    await MainActor.run {
                        guard let mainViewModel = mainViewModel else { return }
                        settings = mainViewModel.settings
                        tempSettings = settings
                        isDirty = false
                    }
                }
            } catch {
                print("加载设置失败: \(error)")
                // 出错时回退到 MainViewModel 的设置
                await MainActor.run {
                    guard let mainViewModel = mainViewModel else { return }
                    settings = mainViewModel.settings
                    tempSettings = settings
                    isDirty = false
                }
            }
        }
    }
    
    func saveSettings() {
        settings = tempSettings
        mainViewModel?.settings = settings
        isDirty = false

        // 通过MainViewModel保存设置（这会触发StorageService）
        mainViewModel?.saveSettings()
    }
    
    func resetSettings() {
        tempSettings = settings
        isDirty = false
    }
    
    func restoreDefaults() {
        tempSettings = AppSettings()
        checkDirty()
    }
    
    // MARK: - Model Management
    func toggleModel(_ modelId: String) {
        tempSettings.toggleModel(modelId)
        checkDirty()
    }
    
    func selectModel(_ modelId: String) {
        tempSettings.updateSelectedModel(modelId)
        checkDirty()
    }
    
    func isModelEnabled(_ modelId: String) -> Bool {
        return tempSettings.enabledModels.contains(modelId)
    }
    
    func isModelSelected(_ modelId: String) -> Bool {
        return tempSettings.selectedModelId == modelId
    }
    
    // MARK: - UI Settings
    func updateFontSize(_ size: Double) {
        tempSettings.fontSize = size
        checkDirty()
    }
    
    func toggleAutoSaveChats() {
        tempSettings.autoSaveChats.toggle()
        checkDirty()
    }
    
    func toggleShowTimestamps() {
        tempSettings.showTimestamps.toggle()
        checkDirty()
    }
    
    func toggleCompactMode() {
        tempSettings.compactMode.toggle()
        checkDirty()
    }
    
    // MARK: - API Settings
    func updateAPIKey(for provider: String, key: String) {
        if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            tempSettings.apiKeys.removeValue(forKey: provider)
        } else {
            tempSettings.apiKeys[provider] = key
        }
        checkDirty()
    }
    
    func updateCustomEndpoint(for provider: String, endpoint: String) {
        if endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            tempSettings.customEndpoints.removeValue(forKey: provider)
        } else {
            tempSettings.customEndpoints[endpoint] = endpoint
        }
        checkDirty()
    }
    
    func getAPIKey(for provider: String) -> String {
        return tempSettings.apiKeys[provider] ?? ""
    }
    
    func getCustomEndpoint(for provider: String) -> String {
        return tempSettings.customEndpoints[provider] ?? ""
    }
    
    // MARK: - Data Management
    func exportSettings() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(tempSettings)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    func importSettings(from jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        
        do {
            let decoder = JSONDecoder()
            let importedSettings = try decoder.decode(AppSettings.self, from: data)
            tempSettings = importedSettings
            checkDirty()
            return true
        } catch {
            return false
        }
    }
    
    func clearAllData() {
        Task {
            do {
                let storageService = try StorageServiceFactory.createService()
                try await storageService.clearAllData()
                
                await MainActor.run {
                    // 重置为默认设置
                    let defaultSettings = AppSettings()
                    tempSettings = defaultSettings
                    settings = defaultSettings
                    mainViewModel?.settings = defaultSettings
                    isDirty = false
                }
            } catch {
                print("清除数据失败: \(error)")
            }
        }
    }
    
    // MARK: - Computed Properties
    var hasUnsavedChanges: Bool {
        return isDirty
    }
    
    var enabledModelsCount: Int {
        return tempSettings.enabledModels.count
    }
    
    var selectedModelInfo: ModelConfig? {
        return availableModels.first { $0.id == tempSettings.selectedModelId }
    }
    
    var fontSizeRange: ClosedRange<Double> {
        return 10.0...24.0
    }
    
    // MARK: - Private Methods
    private func setupDirtyObserver() {
        // 监听临时设置的变化
        $tempSettings
            .dropFirst()
            .sink { [weak self] _ in
                self?.checkDirty()
            }
            .store(in: &cancellables)
    }
    
    private func checkDirty() {
        isDirty = tempSettings != settings
    }
    
    // MARK: - Validation
    func validateSettings() -> [String] {
        var errors: [String] = []
        
        // 检查是否至少启用了一个模型
        if tempSettings.enabledModels.isEmpty {
            errors.append("至少需要启用一个AI模型")
        }
        
        // 检查选中的模型是否被启用
        if !tempSettings.enabledModels.contains(tempSettings.selectedModelId) {
            errors.append("当前选中的模型已被禁用")
        }
        
        // 检查字体大小是否在有效范围内
        if !fontSizeRange.contains(tempSettings.fontSize) {
            errors.append("字体大小必须在\(fontSizeRange.lowerBound)到\(fontSizeRange.upperBound)之间")
        }
        
        return errors
    }
    
    // MARK: - API Key Testing
    
    /// 测试 OpenAI API Key
    func testOpenAIKey() {
        guard let apiKey = tempSettings.apiKeys["openai"], !apiKey.isEmpty else {
            openaiTestStatus = .failed("请先输入 OpenAI API Key")
            return
        }
        
        Task {
            await MainActor.run {
                openaiTestStatus = .testing
            }
            
            let baseURL = configService.getBaseURL(for: "openai")
            let result = await aiAPIClient.testAPIKey(baseURL: baseURL, apiKey: apiKey)
            
            await MainActor.run {
                if result.isValid, let models = result.models {
                    openaiTestStatus = .success

                    // 将 AIModel 转换为 FetchedModel
                    let fetchedModels = models.map { aiModel in
                        FetchedModel(
                            id: aiModel.id,
                            displayName: aiModel.id,  // 直接使用原始ID
                            provider: AIModel.generateProvider(from: aiModel.id),
                            created: aiModel.created,
                            owned_by: aiModel.owned_by
                        )
                    }

                    // 更新设置中的模型列表
                    tempSettings.updateFetchedModels(for: "OpenAI", models: fetchedModels)
                    updateAvailableModels()
                } else {
                    openaiTestStatus = .failed(result.error ?? "测试失败")
                }
            }
        }
    }
    
    /// 测试 Gemini API Key
    func testGeminiKey() {
        guard let apiKey = tempSettings.apiKeys["google"], !apiKey.isEmpty else {
            geminiTestStatus = .failed("请先输入 Gemini API Key")
            return
        }
        
        Task {
            await MainActor.run {
                geminiTestStatus = .testing
            }
            
            let baseURL = configService.getBaseURL(for: "google")
            let result = await aiAPIClient.testAPIKey(baseURL: baseURL, apiKey: apiKey)
            
            await MainActor.run {
                if result.isValid, let models = result.models {
                    geminiTestStatus = .success

                    // 将 AIModel 转换为 FetchedModel
                    let fetchedModels = models.map { aiModel in
                        FetchedModel(
                            id: aiModel.id,
                            displayName: aiModel.id,  // 直接使用原始ID
                            provider: AIModel.generateProvider(from: aiModel.id),
                            created: aiModel.created,
                            owned_by: aiModel.owned_by
                        )
                    }

                    // 更新设置中的模型列表
                    tempSettings.updateFetchedModels(for: "Google", models: fetchedModels)
                    updateAvailableModels()
                } else {
                    geminiTestStatus = .failed(result.error ?? "测试失败")
                }
            }
        }
    }
    
    /// 更新可用模型列表
    private func updateAvailableModels() {
        availableModels = tempSettings.availableModels
    }
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Combine Import
import Combine
