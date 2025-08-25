import SwiftUI

// MARK: - 历史项目视图
struct HistoryItemView: View {
    let session: ChatSession
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 对话图标
                sessionIcon
                
                // 对话信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.displayTitle)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        Text(session.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(session.selectedModel)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // 选中指示器
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            contextMenuItems
        }
        .alert("删除对话", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("确定要删除这个对话吗？此操作无法撤销。")
        }
    }
    
    private var sessionIcon: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 40, height: 40)
            
            Image(systemName: "message")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
        }
    }
    
    private var contextMenuItems: some View {
        Group {
            Button("选择", action: onTap)
            
            Button("重命名") {
                // TODO: 实现重命名功能
            }
            
            Button("复制") {
                // TODO: 实现复制功能
            }
            
            Button("导出") {
                // TODO: 实现导出功能
            }
            
            Divider()
            
            Button("删除", role: .destructive) {
                showingDeleteAlert = true
            }
        }
    }
}

// MARK: - 紧凑历史项目视图
struct CompactHistoryItemView: View {
    let session: ChatSession
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(session.displayTitle)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .blue : .primary)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 侧栏历史项目视图 (macOS)
#if os(macOS)
struct SidebarHistoryItemView: View {
    let session: ChatSession
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Text(session.displayTitle)
                .font(.body)
                .foregroundColor(isSelected ? .primary : .secondary)
                .lineLimit(1)
            
            Spacer()
            
            if isHovered || isSelected {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : 
                      isHovered ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
#endif

// MARK: - 预览
struct HistoryItemView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleSession = ChatSession(
            title: "Swift编程问题讨论",
            selectedModel: "gpt-4"
        )
        
        VStack(spacing: 8) {
            HistoryItemView(
                session: sampleSession,
                isSelected: false,
                onTap: { print("选择") },
                onDelete: { print("删除") }
            )
            
            HistoryItemView(
                session: sampleSession,
                isSelected: true,
                onTap: { print("选择") },
                onDelete: { print("删除") }
            )
            
            CompactHistoryItemView(
                session: sampleSession,
                isSelected: false,
                onTap: { print("选择") }
            )
        }
        .padding()
    }
}
