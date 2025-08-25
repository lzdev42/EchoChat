import SwiftUI

// MARK: - 输入区域视图
struct InputAreaView: View {
    @Binding var text: String
    let canSend: Bool
    let canRegenerate: Bool
    let isLoading: Bool
    let onSend: () -> Void
    let onRegenerate: () -> Void
    let onImageSelected: () -> Void
    let onFileSelected: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // 分隔线
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.secondary.opacity(0.3))
            
            // 输入区域
            HStack(alignment: .bottom, spacing: 12) {
                // 附件按钮
                AttachmentButton(
                    isEnabled: !isLoading,
                    onImageSelected: onImageSelected,
                    onFileSelected: onFileSelected
                )
                
                // 文本输入框
                AdaptiveTextEditor(
                    text: $text,
                    placeholder: "输入消息...",
                    minHeight: 36,
                    maxHeight: 120,
                    fontSize: 16,
                    onCommit: {
                        if canSend {
                            onSend()
                        }
                    }
                )
                
                // 发送/重新生成按钮
                SendButton(
                    canSend: canSend,
                    canRegenerate: canRegenerate,
                    isLoading: isLoading,
                    onSend: onSend,
                    onRegenerate: onRegenerate
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color.secondary.opacity(0.1)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
}

// MARK: - 发送按钮
struct SendButton: View {
    let canSend: Bool
    let canRegenerate: Bool
    let isLoading: Bool
    let onSend: () -> Void
    let onRegenerate: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: buttonAction) {
            Group {
                if isLoading {
                    // 加载指示器
                    LoadingIndicator()
                } else if canSend {
                    // 发送图标
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else if canRegenerate {
                    // 重新生成图标
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                } else {
                    // 禁用状态
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 36, height: 36)
            .background(buttonBackground)
            .clipShape(Circle())
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .disabled(!canSend && !canRegenerate)
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private var buttonBackground: some View {
        Group {
            if isLoading {
                Color.secondary.opacity(0.2)
            } else if canSend {
                Color.blue
            } else if canRegenerate {
                Color.secondary.opacity(0.1)
            } else {
                Color.secondary.opacity(0.1)
            }
        }
    }
    
    private var buttonAction: () -> Void {
        if canSend {
            return onSend
        } else if canRegenerate {
            return onRegenerate
        } else {
            return {}
        }
    }
}

// MARK: - 加载指示器
struct LoadingIndicator: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "arrow.2.circlepath")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - 快捷操作栏 (可选功能)
struct QuickActionsBar: View {
    let onClearChat: () -> Void
    let onExportChat: () -> Void
    
    var body: some View {
        HStack {
            Button("清空对话") {
                onClearChat()
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Spacer()
            
            Button("导出对话") {
                onExportChat()
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
    }
}

// MARK: - 输入建议 (可选功能)
struct InputSuggestions: View {
    let suggestions: [String]
    let onSuggestionTapped: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) {
                        onSuggestionTapped(suggestion)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 预览
struct InputAreaView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            
            // 可以发送状态
            InputAreaView(
                text: .constant("Hello"),
                canSend: true,
                canRegenerate: false,
                isLoading: false,
                onSend: { print("发送") },
                onRegenerate: { print("重新生成") },
                onImageSelected: { print("选择图片") },
                onFileSelected: { print("选择文件") }
            )
            
            // 加载状态
            InputAreaView(
                text: .constant(""),
                canSend: false,
                canRegenerate: false,
                isLoading: true,
                onSend: { print("发送") },
                onRegenerate: { print("重新生成") },
                onImageSelected: { print("选择图片") },
                onFileSelected: { print("选择文件") }
            )
            
            // 可以重新生成状态
            InputAreaView(
                text: .constant(""),
                canSend: false,
                canRegenerate: true,
                isLoading: false,
                onSend: { print("发送") },
                onRegenerate: { print("重新生成") },
                onImageSelected: { print("选择图片") },
                onFileSelected: { print("选择文件") }
            )
        }
                    .background(Color.secondary.opacity(0.1))
    }
}
