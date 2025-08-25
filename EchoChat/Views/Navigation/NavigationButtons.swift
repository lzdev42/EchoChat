import SwiftUI

// MARK: - 导航按钮集合
struct NavigationButtons: View {
    let onHistoryTapped: () -> Void
    let onNewChatTapped: () -> Void
    let onModelSelectorTapped: () -> Void
    let onSettingsTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            HistoryButton(action: onHistoryTapped)
            NewChatButton(action: onNewChatTapped)
            
            Spacer()
            
            ModelSelectorButton(action: onModelSelectorTapped)
            SettingsButton(action: onSettingsTapped)
        }
    }
}

// MARK: - 历史按钮
struct HistoryButton: View {
    let action: () -> Void
    
    var body: some View {
        ActionButton(
            icon: "clock",
            title: "历史",
            action: action
        )
    }
}

// MARK: - 新对话按钮
struct NewChatButton: View {
    let action: () -> Void
    
    var body: some View {
        ActionButton(
            icon: "plus.message",
            title: "新对话",
            isPrimary: true,
            action: action
        )
    }
}

// MARK: - 模型选择按钮
struct ModelSelectorButton: View {
    let action: () -> Void
    
    var body: some View {
        ActionButton(
            icon: "brain",
            title: "模型",
            action: action
        )
    }
}

// MARK: - 设置按钮
struct SettingsButton: View {
    let action: () -> Void
    
    var body: some View {
        ActionButton(
            icon: "gearshape",
            title: "设置",
            action: action
        )
    }
}

// MARK: - 通用操作按钮
struct ActionButton: View {
    let icon: String
    let title: String
    let isPrimary: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    init(
        icon: String,
        title: String,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.isPrimary = isPrimary
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                // 在 macOS 上显示文字标签
                #if os(macOS)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                #endif
            }
            .foregroundColor(isPrimary ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isPrimary ? 0 : 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .help(title) // macOS tooltip
    }
    
    private var backgroundColor: Color {
        if isPrimary {
            return isHovered ? .blue.opacity(0.9) : .blue
        } else {
            if isHovered {
                return Color.secondary.opacity(0.1)
            } else {
                return Color.clear
            }
        }
    }
    
    private var borderColor: Color {
        return Color.secondary.opacity(0.3)
    }
}

// MARK: - 紧凑导航按钮 (用于移动设备)
struct CompactNavigationButtons: View {
    let onHistoryTapped: () -> Void
    let onNewChatTapped: () -> Void
    let onModelSelectorTapped: () -> Void
    let onSettingsTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            CompactButton(icon: "clock", action: onHistoryTapped)
            CompactButton(icon: "plus.message", action: onNewChatTapped)
            
            Spacer()
            
            CompactButton(icon: "brain", action: onModelSelectorTapped)
            CompactButton(icon: "gearshape", action: onSettingsTapped)
        }
    }
}

// MARK: - 紧凑按钮
struct CompactButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 工具栏按钮 (用于 macOS)
#if os(macOS)
struct ToolbarNavigationButtons: View {
    let onHistoryTapped: () -> Void
    let onNewChatTapped: () -> Void
    let onModelSelectorTapped: () -> Void
    let onSettingsTapped: () -> Void
    
    var body: some View {
        HStack {
            Group {
                Button("历史", action: onHistoryTapped)
                Button("新对话", action: onNewChatTapped)
            }
            .help("查看历史对话")
            
            Spacer()
            
            Group {
                Button("模型", action: onModelSelectorTapped)
                Button("设置", action: onSettingsTapped)
            }
        }
    }
}
#endif

// MARK: - 预览
struct NavigationButtons_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            NavigationButtons(
                onHistoryTapped: { print("历史") },
                onNewChatTapped: { print("新对话") },
                onModelSelectorTapped: { print("模型选择") },
                onSettingsTapped: { print("设置") }
            )
            .padding()
            
            CompactNavigationButtons(
                onHistoryTapped: { print("历史") },
                onNewChatTapped: { print("新对话") },
                onModelSelectorTapped: { print("模型选择") },
                onSettingsTapped: { print("设置") }
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
