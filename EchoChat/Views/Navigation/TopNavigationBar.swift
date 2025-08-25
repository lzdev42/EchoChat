import SwiftUI

// MARK: - 顶部导航栏
struct TopNavigationBar: View {
    let title: String
    let onHistoryTapped: () -> Void
    let onNewChatTapped: () -> Void
    let onModelSelectorTapped: () -> Void
    let onSettingsTapped: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            // 左侧按钮组
            HStack(spacing: 12) {
                NavigationBarButton(
                    icon: "clock",
                    title: "历史",
                    action: onHistoryTapped
                )
                
                NavigationBarButton(
                    icon: "plus.message",
                    title: "新对话",
                    action: onNewChatTapped
                )
            }
            
            Spacer()
            
            // 中间标题
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            // 右侧按钮组
            HStack(spacing: 12) {
                NavigationBarButton(
                    icon: "brain",
                    title: "模型",
                    action: onModelSelectorTapped
                )
                
                NavigationBarButton(
                    icon: "gearshape",
                    title: "设置",
                    action: onSettingsTapped
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color.secondary.opacity(0.05)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.secondary.opacity(0.3)),
            alignment: .bottom
        )
    }
}

// MARK: - 导航栏按钮
struct NavigationBarButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                #if os(macOS)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                #endif
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPressed ? Color.secondary.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .help(title) // macOS tooltip
    }
}

// MARK: - 导航栏按钮样式 (iOS)
#if os(iOS)
private struct NavigationBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
#endif

// MARK: - 预览
struct TopNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TopNavigationBar(
                title: "Swift编程问题",
                onHistoryTapped: { print("历史") },
                onNewChatTapped: { print("新对话") },
                onModelSelectorTapped: { print("模型选择") },
                onSettingsTapped: { print("设置") }
            )
            
            TopNavigationBar(
                title: "这是一个非常长的对话标题用来测试截断效果",
                onHistoryTapped: { print("历史") },
                onNewChatTapped: { print("新对话") },
                onModelSelectorTapped: { print("模型选择") },
                onSettingsTapped: { print("设置") }
            )
            
            Spacer()
        }
        .previewLayout(.sizeThatFits)
    }
}
