import SwiftUI

// MARK: - 模型选择器视图
struct ModelSelectorView: View {
    @ObservedObject var mainViewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(mainViewModel.settings.availableModels) { model in
                    ModelSelectorRow(
                        model: model,
                        isSelected: model.id == mainViewModel.settings.selectedModelId,
                        onSelect: {
                            mainViewModel.selectModel(model.id)
                            dismiss()
                        }
                    )
                }
            }
            .navigationTitle("选择模型")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 模型选择行
struct ModelSelectorRow: View {
    let model: ModelConfig
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(model.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    
                    Text(model.provider)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 模型特性标签
                    HStack(spacing: 8) {
                        if model.supportsImages {
                            FeatureTag(icon: "photo", text: "图片")
                        }
                        
                        if model.supportsFiles {
                            FeatureTag(icon: "doc", text: "文件")
                        }
                        
                        FeatureTag(icon: "textformat", text: "\(model.maxTokens / 1000)K")
                        
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - 特性标签
struct FeatureTag: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(4)
    }
}

// MARK: - 快速模型选择器 (用于工具栏)
struct QuickModelSelector: View {
    @ObservedObject var mainViewModel: MainViewModel
    @State private var showingModelSelector = false
    
    var body: some View {
        Button(action: {
            showingModelSelector = true
        }) {
            HStack(spacing: 4) {
                Text(currentModelDisplayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingModelSelector) {
            ModelSelectorView(mainViewModel: mainViewModel)
        }
    }
    
    private var currentModelDisplayName: String {
        let selectedModel = mainViewModel.settings.selectedModel
        return selectedModel.displayName
    }
}

// MARK: - 紧凑模型选择器
struct CompactModelSelector: View {
    @ObservedObject var mainViewModel: MainViewModel
    
    var body: some View {
        Menu {
            ForEach(mainViewModel.settings.availableModels) { model in
                Button(action: {
                    mainViewModel.selectModel(model.id)
                }) {
                    HStack {
                        Text(model.displayName)
                        
                        if model.id == mainViewModel.settings.selectedModelId {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "brain")
                    .font(.system(size: 16, weight: .medium))
                
                #if os(macOS)
                Text(currentModelDisplayName)
                    .font(.system(size: 14, weight: .medium))
                #endif
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var currentModelDisplayName: String {
        let selectedModel = mainViewModel.settings.selectedModel
        return selectedModel.displayName
    }
}

// MARK: - 模型状态指示器
struct ModelStatusIndicator: View {
    let model: ModelConfig
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Circle()
                    .fill(model.isEnabled ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            
            Text(model.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 预览
struct ModelSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        let mainViewModel = MainViewModel()
        
        VStack(spacing: 20) {
            ModelSelectorView(mainViewModel: mainViewModel)
            
            QuickModelSelector(mainViewModel: mainViewModel)
            
            CompactModelSelector(mainViewModel: mainViewModel)
        }
    }
}
