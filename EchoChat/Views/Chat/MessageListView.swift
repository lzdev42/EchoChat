import SwiftUI

// MARK: - 消息列表视图
struct MessageListView: View {
    let messages: [ChatMessage]
    let isLoading: Bool
    let onDeleteMessage: (ChatMessage) -> Void
    let onResendMessage: (ChatMessage) -> Void
    let onStartEditingMessage: (ChatMessage) -> Void
    let onSaveEditedMessage: (ChatMessage, String) -> Void
    let onCancelEditingMessage: (ChatMessage) -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // 消息列表
                    ForEach(messages) { message in
                        MessageBubbleView(
                            message: message,
                            onDelete: { onDeleteMessage(message) },
                            onResend: { onResendMessage(message) },
                            onStartEditing: { onStartEditingMessage(message) },
                            onSaveEditing: { content in onSaveEditedMessage(message, content) },
                            onCancelEditing: { onCancelEditingMessage(message) }
                        )
                        .id(message.id)
                    }
                    
                    // 底部间距
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: messages.count) { _, _ in
                // 新消息时滚动到底部
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: isLoading) { _, loading in
                // 加载状态变化时也滚动到底部
                if !loading {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.secondary.opacity(0.05))
        .overlay(
            Group {
                if messages.isEmpty {
                    EmptyMessageView()
                }
            }
        )
    }
}

// MARK: - 空消息视图
struct EmptyMessageView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("开始新对话")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("在下方输入框中输入消息开始对话")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.05))
    }
}

// MARK: - 预览
struct MessageListView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMessages = [
            ChatMessage(
                content: "你好！我想学习SwiftUI，有什么建议吗？",
                sender: .user,
                session: nil
            ),
            ChatMessage(
                content: "很高兴你想学习SwiftUI！SwiftUI是苹果的声明式UI框架，它让创建用户界面变得更加直观和高效。\n\n建议你从以下几个方面开始：\n\n1. **基础概念**：了解声明式编程的思想\n2. **基本组件**：学习Text、Button、Image等基础视图\n3. **布局系统**：掌握VStack、HStack、ZStack的使用\n4. **状态管理**：理解@State、@Binding等属性包装器\n\n你现在的SwiftUI基础如何？",
                sender: .assistant,
                session: nil
            ),
            ChatMessage(
                content: "这是一个发送中的消息",
                sender: .assistant,
                status: .sending,
                session: nil
            )
        ]
        
        VStack {
            // 有消息的状态
            MessageListView(
                messages: sampleMessages,
                isLoading: false,
                onDeleteMessage: { _ in },
                onResendMessage: { _ in },
                onStartEditingMessage: { _ in },
                onSaveEditedMessage: { _, _ in },
                onCancelEditingMessage: { _ in }
            )

            // 空消息状态
            MessageListView(
                messages: [],
                isLoading: false,
                onDeleteMessage: { _ in },
                onResendMessage: { _ in },
                onStartEditingMessage: { _ in },
                onSaveEditedMessage: { _, _ in },
                onCancelEditingMessage: { _ in }
            )
        }
    }
}
