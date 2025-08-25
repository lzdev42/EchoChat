import SwiftUI

// MARK: - 消息气泡视图
struct MessageBubbleView: View {
    let message: ChatMessage
    let onDelete: () -> Void
    let onResend: () -> Void
    let onStartEditing: () -> Void
    let onSaveEditing: (String) -> Void
    let onCancelEditing: () -> Void

    @State private var showingContextMenu = false
    @State private var editText: String = ""
    @FocusState private var isEditFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    init(
        message: ChatMessage,
        onDelete: @escaping () -> Void,
        onResend: @escaping () -> Void,
        onStartEditing: @escaping () -> Void = {},
        onSaveEditing: @escaping (String) -> Void = { _ in },
        onCancelEditing: @escaping () -> Void = {}
    ) {
        self.message = message
        self.onDelete = onDelete
        self.onResend = onResend
        self.onStartEditing = onStartEditing
        self.onSaveEditing = onSaveEditing
        self.onCancelEditing = onCancelEditing
        self._editText = State(initialValue: message.content)
        // Note: FocusState is automatically initialized and will be set in onAppear if needed
    }

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 50)
                messageContent
            } else {
                messageContent
                Spacer(minLength: 50)
            }
        }
        .contextMenu {
            contextMenuItems
        }
        .onAppear {
            // If the message is in editing mode, focus the text editor
            if message.isEditing {
                isEditFocused = true
            }
        }
    }
    
    private var messageContent: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
            // 消息内容
            messageBubble
            
            // 消息状态和时间
            messageFooter
        }
    }
    
    private var messageBubble: some View {
        Group {
            if message.isEditing {
                editModeBubble
            } else {
                displayModeBubble
            }
        }
        .background(bubbleBackground)
        .clipShape(BubbleShape(isFromUser: message.isFromUser))
        .overlay(
            // 加载状态指示器
            Group {
                if message.isTemporary {
                    loadingIndicator
                }
            }
        )
    }

    private var displayModeBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 消息文本
            Text(message.displayContent)
                .font(.body)
                .foregroundColor(message.isFromUser ? .white : .primary)
                .multilineTextAlignment(.leading)

            // 编辑标记
            if message.isEdited {
                Text("(已编辑)")
                    .font(.caption2)
                    .foregroundColor(message.isFromUser ? .white.opacity(0.7) : .secondary)
            }

            // 附件（如果有）
            if message.hasAttachment {
                attachmentView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var editModeBubble: some View {
        VStack(alignment: .leading, spacing: 12) {
            editTextArea
            editActionButtons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var editTextArea: some View {
        ZStack(alignment: .topLeading) {
            editPlaceholder
            editTextEditor
        }
        .background(editTextBackground)
        .overlay(editTextBorder)
    }
    
    private var editPlaceholder: some View {
        Group {
            if editText.isEmpty {
                Text("编辑消息...")
                    .foregroundColor(message.isFromUser ? .white.opacity(0.5) : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var editTextEditor: some View {
        TextEditor(text: $editText)
            .font(.body)
            .foregroundColor(message.isFromUser ? .white : .primary)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .frame(minHeight: 60, maxHeight: 150)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .focused($isEditFocused)
            .onChange(of: editText) { oldValue, newValue in
                // 确保编辑时内容可见
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    // 触发重新布局确保滚动正确
                }
            }
            .onSubmit {
                // 支持回车键保存
                if !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onSaveEditing(editText)
                }
            }
    }
    
    private var editTextBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(message.isFromUser ? Color.white.opacity(0.15) : Color.secondary.opacity(0.15))
    }
    
    private var editTextBorder: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(message.isFromUser ? Color.white.opacity(0.4) : Color.secondary.opacity(0.4), lineWidth: 1)
    }
    
    private var editActionButtons: some View {
        HStack(spacing: 12) {
            Button("取消") {
                onCancelEditing()
            }
            .buttonStyle(.borderless)
            .foregroundColor(message.isFromUser ? .white.opacity(0.8) : .secondary)

            Button("保存") {
                onSaveEditing(editText)
            }
            .buttonStyle(.borderedProminent)
            .tint(message.isFromUser ? .white : .blue)
            .foregroundColor(message.isFromUser ? .blue : .white)
        }
        .font(.caption)
    }
    
    private var bubbleBackground: some View {
        Group {
            if message.isFromUser {
                Color.blue
            } else {
                Color.secondary.opacity(0.2)
            }
        }
    }
    
    private var messageFooter: some View {
        HStack(spacing: 4) {
            if message.isFromUser {
                Spacer()
            }
            
            // 时间戳
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // 消息状态
            if message.isFromUser {
                statusIcon
            }
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
    
    private var statusIcon: some View {
        Group {
            switch message.status {
            case .sending:
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
            case .sent:
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            case .failed:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
            case .regenerating:
                EmptyView()
            }
        }
        .font(.caption2)
    }
    
    private var loadingIndicator: some View {
        HStack {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(loadingScale(for: index))
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: message.isTemporary
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var attachmentView: some View {
        Group {
            if let attachmentName = message.attachmentName {
                HStack {
                    Image(systemName: message.type == .image ? "photo" : "doc")
                        .foregroundColor(.secondary)
                    
                    Text(attachmentName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var contextMenuItems: some View {
        Group {
            Button("复制", action: copyMessage)

            if !message.isEditing {
                Button("编辑") {
                    onStartEditing()
                }
            }

            if message.sender == .user && message.status == .failed {
                Button("重新发送", action: onResend)
            }

            Button("删除", role: .destructive, action: onDelete)
        }
    }
    
    // MARK: - Helper Methods
    private func loadingScale(for index: Int) -> CGFloat {
        return message.isTemporary ? (sin(Date().timeIntervalSince1970 * 2 + Double(index) * 0.5) * 0.3 + 0.7) : 1.0
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "'昨天' HH:mm"
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
        }
        
        return formatter.string(from: date)
    }
    
    private func copyMessage() {
        #if os(iOS)
        UIPasteboard.general.string = message.content
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
        #endif
    }
}

// MARK: - 气泡形状
struct BubbleShape: Shape {
    let isFromUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 8
        
        var path = Path()
        
        if isFromUser {
            // 用户消息气泡 (右对齐，右下角有小尾巴)
            path.move(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
            path.addArc(center: CGPoint(x: rect.width - radius, y: radius), 
                       radius: radius, 
                       startAngle: .degrees(-90), 
                       endAngle: .degrees(0), 
                       clockwise: false)
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius - tailSize))
            path.addLine(to: CGPoint(x: rect.width + tailSize, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width - radius, y: rect.height))
            path.addArc(center: CGPoint(x: rect.width - radius, y: rect.height - radius), 
                       radius: radius, 
                       startAngle: .degrees(0), 
                       endAngle: .degrees(90), 
                       clockwise: false)
            path.addLine(to: CGPoint(x: radius, y: rect.height))
            path.addArc(center: CGPoint(x: radius, y: rect.height - radius), 
                       radius: radius, 
                       startAngle: .degrees(90), 
                       endAngle: .degrees(180), 
                       clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addArc(center: CGPoint(x: radius, y: radius), 
                       radius: radius, 
                       startAngle: .degrees(180), 
                       endAngle: .degrees(270), 
                       clockwise: false)
        } else {
            // AI消息气泡 (左对齐，左下角有小尾巴)
            path.move(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
            path.addArc(center: CGPoint(x: rect.width - radius, y: radius), 
                       radius: radius, 
                       startAngle: .degrees(-90), 
                       endAngle: .degrees(0), 
                       clockwise: false)
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
            path.addArc(center: CGPoint(x: rect.width - radius, y: rect.height - radius), 
                       radius: radius, 
                       startAngle: .degrees(0), 
                       endAngle: .degrees(90), 
                       clockwise: false)
            path.addLine(to: CGPoint(x: radius, y: rect.height))
            path.addLine(to: CGPoint(x: -tailSize, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height - radius - tailSize))
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addArc(center: CGPoint(x: radius, y: radius), 
                       radius: radius, 
                       startAngle: .degrees(180), 
                       endAngle: .degrees(270), 
                       clockwise: false)
        }
        
        return path
    }
}

// MARK: - 预览
struct MessageBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // 用户消息
            MessageBubbleView(
                message: ChatMessage(
                    content: "你好！我想学习SwiftUI，有什么建议吗？",
                    sender: .user,
                    session: nil
                ),
                onDelete: {},
                onResend: {},
                onStartEditing: {},
                onSaveEditing: { _ in },
                onCancelEditing: {}
            )
            
            // AI回复
            MessageBubbleView(
                message: ChatMessage(
                    content: "很高兴你想学习SwiftUI！这是一个很好的选择。",
                    sender: .assistant,
                    session: nil
                ),
                onDelete: {},
                onResend: {},
                onStartEditing: {},
                onSaveEditing: { _ in },
                onCancelEditing: {}
            )

            // 加载中的消息
            MessageBubbleView(
                message: ChatMessage(
                    content: "",
                    sender: .assistant,
                    status: .sending,
                    session: nil
                ),
                onDelete: {},
                onResend: {},
                onStartEditing: {},
                onSaveEditing: { _ in },
                onCancelEditing: {}
            )
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
    }
}
