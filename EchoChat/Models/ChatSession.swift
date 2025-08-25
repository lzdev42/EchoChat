import Foundation
import SwiftData

// MARK: - 聊天会话模型
@Model
class ChatSession: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var selectedModel: String
    var isActive: Bool
    
    // SwiftData 关系：一个会话包含多条消息
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage] = []
    
    init(
        id: UUID = UUID(),
        title: String = "新对话",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        selectedModel: String = "gpt-4",
        isActive: Bool = false
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.selectedModel = selectedModel
        self.isActive = isActive
    }
}

// MARK: - 便利扩展
extension ChatSession {
    var displayTitle: String {
        return title.isEmpty ? "新对话" : title
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(updatedAt) {
            formatter.dateFormat = "HH:mm"
            return "今天 \(formatter.string(from: updatedAt))"
        } else if calendar.isDateInYesterday(updatedAt) {
            formatter.dateFormat = "HH:mm"
            return "昨天 \(formatter.string(from: updatedAt))"
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: updatedAt)
        }
    }
    
    func updateTimestamp() {
        updatedAt = Date()
    }
    
    func updateTitle(_ newTitle: String) {
        title = newTitle
        updatedAt = Date()
    }
}
