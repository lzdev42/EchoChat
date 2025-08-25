import Foundation

// MARK: - 存储服务协议
protocol StorageServiceProtocol {
    // 会话管理
    func saveSessions(_ sessions: [ChatSession]) async throws
    func loadSessions() async throws -> [ChatSession]
    func deleteSession(_ sessionId: UUID) async throws
    
    // 消息管理
    func saveMessages(_ messages: [ChatMessage], for sessionId: UUID) async throws
    func loadMessages(for sessionId: UUID) async throws -> [ChatMessage]
    func deleteMessages(for sessionId: UUID) async throws
    
    // 设置管理
    func saveSettings(_ settings: AppSettings) async throws
    func loadSettings() async throws -> AppSettings?
    
    // 数据导出/导入
    func exportData() async throws -> Data
    func importData(_ data: Data) async throws
    func clearAllData() async throws
}

// MARK: - 存储服务错误
enum StorageServiceError: LocalizedError {
    case fileNotFound
    case writeError(String)
    case readError(String)
    case corruptedData
    case insufficientSpace
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "文件未找到"
        case .writeError(let message):
            return "写入错误: \(message)"
        case .readError(let message):
            return "读取错误: \(message)"
        case .corruptedData:
            return "数据已损坏"
        case .insufficientSpace:
            return "存储空间不足"
        case .permissionDenied:
            return "没有访问权限"
        }
    }
}

// MARK: - 本地存储服务实现 (现在使用 SwiftData，大部分功能已迁移)
class LocalStorageService: StorageServiceProtocol {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    init() throws {
        documentsDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("EchoChat")
        
        try createDirectoryIfNeeded()
    }
    
    // MARK: - 会话管理 (现在由 SwiftData 直接处理)
    func saveSessions(_ sessions: [ChatSession]) async throws {
        // SwiftData 自动处理持久化，此方法保留以维持协议兼容性
        // 实际保存由 ModelContext.save() 完成
    }
    
    func loadSessions() async throws -> [ChatSession] {
        // SwiftData 通过 @Query 或 FetchDescriptor 直接加载
        // 此方法保留以维持协议兼容性
        return []
    }
    
    func deleteSession(_ sessionId: UUID) async throws {
        // SwiftData 通过 ModelContext.delete() 直接删除
        // 此方法保留以维持协议兼容性
    }
    
    // MARK: - 消息管理 (现在由 SwiftData 直接处理)
    func saveMessages(_ messages: [ChatMessage], for sessionId: UUID) async throws {
        // SwiftData 自动处理持久化，此方法保留以维持协议兼容性
    }
    
    func loadMessages(for sessionId: UUID) async throws -> [ChatMessage] {
        // SwiftData 通过关系自动加载：session.messages
        return []
    }
    
    func deleteMessages(for sessionId: UUID) async throws {
        // SwiftData 通过 @Relationship(deleteRule: .cascade) 自动删除
    }
    
    // MARK: - 设置管理
    func saveSettings(_ settings: AppSettings) async throws {
        let data = try JSONEncoder().encode(settings)
        let url = documentsDirectory.appendingPathComponent("settings.json")
        try data.write(to: url)
    }
    
    func loadSettings() async throws -> AppSettings? {
        let url = documentsDirectory.appendingPathComponent("settings.json")
        
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AppSettings.self, from: data)
    }
    
    // MARK: - 数据导出/导入 (TODO: 将来实现 SwiftData 的导出功能)
    func exportData() async throws -> Data {
        // TODO: 实现 SwiftData 数据的导出
        // 需要创建简单的数据传输对象来序列化 SwiftData 模型
        let exportData: [String: Any] = ["note": "SwiftData export not yet implemented"]
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    func importData(_ data: Data) async throws {
        // TODO: 实现 SwiftData 数据的导入
        throw StorageServiceError.corruptedData
    }
    
    func clearAllData() async throws {
        if fileManager.fileExists(atPath: documentsDirectory.path) {
            try fileManager.removeItem(at: documentsDirectory)
        }
        try createDirectoryIfNeeded()
    }
    
    // MARK: - Private Methods
    private func createDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            try fileManager.createDirectory(
                at: documentsDirectory,
                withIntermediateDirectories: true
            )
        }
    }
}

// MARK: - 工厂类
class StorageServiceFactory {
    static func createService() throws -> StorageServiceProtocol {
        return try LocalStorageService()
    }
}
