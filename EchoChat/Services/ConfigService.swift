import Foundation
#if os(iOS)
import UIKit
#endif
// MARK: - 配置服务协议
protocol ConfigServiceProtocol {
    // 应用配置
    func getAppVersion() -> String
    func getBuildNumber() -> String
    func getAppName() -> String
    
    // 模型配置
    func getAvailableModels() -> [ModelConfig]
    func getModelConfig(for modelId: String) -> ModelConfig?
    func updateModelConfig(_ config: ModelConfig)
    
    // API配置
    func getAPIEndpoint(for provider: String) -> String?
    func setAPIEndpoint(_ endpoint: String, for provider: String)
    func validateAPIKey(_ key: String, for provider: String) -> Bool
    
    // 功能开关
    func isFeatureEnabled(_ feature: AppFeature) -> Bool
    func enableFeature(_ feature: AppFeature, enabled: Bool)
    
    // 缓存管理
    func clearCache()
    func getCacheSize() -> Int64
}

// MARK: - 应用功能枚举
enum AppFeature: String, CaseIterable {
    case imageUpload = "image_upload"
    case fileUpload = "file_upload"
    case voiceInput = "voice_input"
    case streamingResponse = "streaming_response"
    case darkMode = "dark_mode"
    case exportChat = "export_chat"
    case multiSession = "multi_session"
    case customModels = "custom_models"
}

// MARK: - 配置服务实现
class ConfigService: ConfigServiceProtocol {
    private let userDefaults = UserDefaults.standard
    private let bundle = Bundle.main
    
    // MARK: - 应用配置
    func getAppVersion() -> String {
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    func getBuildNumber() -> String {
        return bundle.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    func getAppName() -> String {
        return bundle.infoDictionary?["CFBundleDisplayName"] as? String ?? "EchoChat"
    }
    
    // MARK: - 模型配置
    func getAvailableModels() -> [ModelConfig] {
        return ModelConfig.defaultModels.filter { model in
            isFeatureEnabled(.customModels) || !model.id.contains("custom")
        }
    }
    
    func getModelConfig(for modelId: String) -> ModelConfig? {
        return getAvailableModels().first { $0.id == modelId }
    }
    
    func updateModelConfig(_ config: ModelConfig) {
        // TODO: 实现自定义模型配置保存
        // 预留给您后续开发
    }
    
    // MARK: - API配置
    func getAPIEndpoint(for provider: String) -> String? {
        let key = "api_endpoint_\(provider)"
        return userDefaults.string(forKey: key) ?? getDefaultEndpoint(for: provider)
    }
    
    func setAPIEndpoint(_ endpoint: String, for provider: String) {
        let key = "api_endpoint_\(provider)"
        userDefaults.set(endpoint, forKey: key)
    }
    
    func validateAPIKey(_ key: String, for provider: String) -> Bool {
        // 基本格式验证
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch provider.lowercased() {
        case "openai":
            return trimmedKey.hasPrefix("sk-") && trimmedKey.count > 20
        case "anthropic":
            return trimmedKey.hasPrefix("claude-") || trimmedKey.hasPrefix("sk-ant-")
        case "google":
            return trimmedKey.hasPrefix("AIzaSy") && trimmedKey.count > 30
        default:
            return !trimmedKey.isEmpty
        }
    }
    
    /// 获取 API 基础 URL
    func getBaseURL(for provider: String) -> String {
        return getAPIEndpoint(for: provider) ?? getDefaultEndpoint(for: provider) ?? "https://api.openai.com/v1"
    }
    
    // MARK: - 功能开关
    func isFeatureEnabled(_ feature: AppFeature) -> Bool {
        let key = "feature_\(feature.rawValue)"
        
        // 默认功能状态
        let defaultEnabled: Bool
        switch feature {
        case .imageUpload, .fileUpload, .streamingResponse, .exportChat, .multiSession:
            defaultEnabled = true
        case .voiceInput, .customModels:
            defaultEnabled = false
        case .darkMode:
            defaultEnabled = true
        }
        
        return userDefaults.object(forKey: key) as? Bool ?? defaultEnabled
    }
    
    func enableFeature(_ feature: AppFeature, enabled: Bool) {
        let key = "feature_\(feature.rawValue)"
        userDefaults.set(enabled, forKey: key)
    }
    
    // MARK: - 缓存管理
    func clearCache() {
        // 清除临时文件
        let tempDirectory = FileManager.default.temporaryDirectory
        let echoChatTemp = tempDirectory.appendingPathComponent("EchoChat")
        
        try? FileManager.default.removeItem(at: echoChatTemp)
        
        // 清除UserDefaults中的缓存数据
        let cachePrefixes = ["cache_", "temp_"]
        for key in userDefaults.dictionaryRepresentation().keys {
            for prefix in cachePrefixes {
                if key.hasPrefix(prefix) {
                    userDefaults.removeObject(forKey: key)
                }
            }
        }
    }
    
    func getCacheSize() -> Int64 {
        let tempDirectory = FileManager.default.temporaryDirectory
        let echoChatTemp = tempDirectory.appendingPathComponent("EchoChat")
        
        guard let enumerator = FileManager.default.enumerator(at: echoChatTemp, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    // MARK: - Private Methods
    private func getDefaultEndpoint(for provider: String) -> String? {
        switch provider.lowercased() {
        case "openai":
            return "https://api.openai.com/v1"
        case "anthropic":
            return "https://api.anthropic.com"
        case "google":
            return "https://generativelanguage.googleapis.com/v1beta/openai"
        default:
            return nil
        }
    }
}

// MARK: - 配置服务扩展
extension ConfigService {
    // 获取格式化的缓存大小
    func getFormattedCacheSize() -> String {
        let bytes = getCacheSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // 获取系统信息
    func getSystemInfo() -> [String: String] {
        var info: [String: String] = [:]
        
        info["应用版本"] = getAppVersion()
        info["构建版本"] = getBuildNumber()
        info["应用名称"] = getAppName()
        
        #if os(iOS)
        info["系统"] = "iOS \(UIDevice.current.systemVersion)"
        info["设备"] = UIDevice.current.model
        #elseif os(macOS)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        info["系统"] = "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #endif
        
        info["缓存大小"] = getFormattedCacheSize()
        
        return info
    }
}

// MARK: - 工厂类
class ConfigServiceFactory {
    static func createService() -> ConfigServiceProtocol {
        return ConfigService()
    }
}
