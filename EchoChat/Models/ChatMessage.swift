import Foundation
import SwiftData

// MARK: - 消息发送者类型
enum MessageSender: String, Codable, CaseIterable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

// MARK: - 消息类型
enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case file = "file"
}

// MARK: - 消息状态
enum MessageStatus: String, Codable {
    case sending = "sending"
    case sent = "sent"
    case failed = "failed"
    case regenerating = "regenerating"
}

// MARK: - 聊天消息模型
@Model
class ChatMessage: Identifiable {
    @Attribute(.unique) var id: UUID
    var content: String
    var sender: MessageSender
    var type: MessageType
    var timestamp: Date
    var status: MessageStatus

    // 编辑相关属性
    var isEditing: Bool = false
    var editedAt: Date?
    var originalContent: String?

    // 附件相关属性
    var attachmentURL: URL?
    var attachmentName: String?
    
    // SwiftData 关系：消息属于某个会话
    var session: ChatSession?
    
    init(
        id: UUID = UUID(),
        content: String,
        sender: MessageSender,
        type: MessageType = .text,
        timestamp: Date = Date(),
        status: MessageStatus = .sent,
        session: ChatSession? = nil,
        attachmentURL: URL? = nil,
        attachmentName: String? = nil,
        isEditing: Bool = false,
        editedAt: Date? = nil,
        originalContent: String? = nil
    ) {
        self.id = id
        self.content = content
        self.sender = sender
        self.type = type
        self.timestamp = timestamp
        self.status = status
        self.session = session
        self.attachmentURL = attachmentURL
        self.attachmentName = attachmentName
        self.isEditing = isEditing
        self.editedAt = editedAt
        self.originalContent = originalContent
    }
}

// MARK: - 便利扩展
extension ChatMessage {
    var isFromUser: Bool {
        return sender == .user
    }
    
    var isFromAssistant: Bool {
        return sender == .assistant
    }
    
    var hasAttachment: Bool {
        return attachmentURL != nil
    }
    
    var isTemporary: Bool {
        return status == .sending || status == .regenerating
    }

    // 编辑相关便利方法
    var isEdited: Bool {
        return editedAt != nil
    }

    var displayContent: String {
        return content.isEmpty ? "..." : content
    }

    func startEditing() {
        isEditing = true
        originalContent = content
    }

    func cancelEditing() {
        isEditing = false
        originalContent = nil
        if let original = originalContent {
            content = original
        }
    }

    func finishEditing() {
        isEditing = false
        editedAt = Date()
        originalContent = nil
    }
}
