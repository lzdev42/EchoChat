import SwiftUI

// MARK: - 设置视图
struct SettingsView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var mainViewModel: MainViewModel
    
    init(settingsViewModel: SettingsViewModel, mainViewModel: MainViewModel) {
        self.settingsViewModel = settingsViewModel
        self.mainViewModel = mainViewModel
        print("🔥 SettingsView 初始化完成！")
    }
    
    var body: some View {
        print("✅ SettingsView body 正在渲染！")
        return Group {
                        #if os(macOS)
            // macOS 简化版设置
            ScrollView {
                VStack(spacing: 24) {
                    // API 配置 - 核心功能
                    SectionView(title: "AI API 配置") {
                        apiConfigurationSection
                    }

                    // 简化的界面设置
                    SectionView(title: "界面设置") {
                        simpleInterfaceSettingsSection
                    }
                }
                .padding()
            }
            .frame(minWidth: 500, minHeight: 400)
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        settingsViewModel.saveSettings()
                        mainViewModel.isSettingsPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
            #else
            // iOS 简化版设置
            NavigationView {
                List {
                    // API 配置 - 核心功能
                    Section("AI API 配置") {
                        apiConfigurationSection
                    }

                    // 简化的界面设置
                    Section("界面设置") {
                        simpleInterfaceSettingsSection
                    }
                }
                .navigationTitle("设置")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") {
                            settingsViewModel.saveSettings()
                            mainViewModel.isSettingsPresented = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            #endif
        }
        .onAppear {
            settingsViewModel.loadSettings()
        }
    }
    
    // MARK: - 模型设置部分
    private var modelSettingsSection: some View {
        Group {
            // 当前选中的模型
            HStack {
                Text("当前模型")
                Spacer()
                Text(settingsViewModel.selectedModelInfo?.displayName ?? "未知")
                    .foregroundColor(.secondary)
            }

            #if os(macOS)
            // macOS 使用按钮打开模型管理
            Button("模型管理") {
                // TODO: 实现macOS的模型管理弹窗
            }
            .buttonStyle(.bordered)
            #else
            // iOS 使用 NavigationLink
            NavigationLink("模型管理") {
                ModelManagementView(settingsViewModel: settingsViewModel)
            }
            #endif
        }
    }
    
    // MARK: - 简化的界面设置部分
    private var simpleInterfaceSettingsSection: some View {
        Group {
            // 字体大小 - 简化为3个选项
            HStack {
                Text("字体大小")
                Spacer()
                Picker("", selection: Binding(
                    get: { settingsViewModel.tempSettings.fontSize },
                    set: { settingsViewModel.updateFontSize($0) }
                )) {
                    Text("小").tag(12.0)
                    Text("中").tag(14.0)
                    Text("大").tag(16.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            // 自动保存对话
            Toggle("自动保存对话", isOn: Binding(
                get: { settingsViewModel.tempSettings.autoSaveChats },
                set: { _ in settingsViewModel.toggleAutoSaveChats() }
            ))
        }
    }
    
    // MARK: - 简化的API 配置部分
    private var apiConfigurationSection: some View {
        Group {
            // OpenAI API Key
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("OpenAI API Key")
                        .fontWeight(.medium)
                    Spacer()
                    if !settingsViewModel.getAPIKey(for: "OpenAI").isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                SecureField("sk-...", text: Binding(
                    get: { settingsViewModel.getAPIKey(for: "OpenAI") },
                    set: { settingsViewModel.updateAPIKey(for: "OpenAI", key: $0) }
                ))
                #if os(macOS)
                .textFieldStyle(.squareBorder)
                #else
                .textFieldStyle(.roundedBorder)
                #endif
                .font(.system(.body, design: .monospaced))

                Button("测试并获取模型") {
                    settingsViewModel.testOpenAIKey()
                }
                .buttonStyle(.bordered)
                .disabled(settingsViewModel.getAPIKey(for: "OpenAI").isEmpty)
            }

            // Gemini API Key
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Gemini API Key")
                        .fontWeight(.medium)
                    Spacer()
                    if !settingsViewModel.getAPIKey(for: "Google").isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                SecureField("AIzaSy...", text: Binding(
                    get: { settingsViewModel.getAPIKey(for: "Google") },
                    set: { settingsViewModel.updateAPIKey(for: "Google", key: $0) }
                ))
                #if os(macOS)
                .textFieldStyle(.squareBorder)
                #else
                .textFieldStyle(.roundedBorder)
                #endif
                .font(.system(.body, design: .monospaced))

                Button("测试并获取模型") {
                    settingsViewModel.testGeminiKey()
                }
                .buttonStyle(.bordered)
                .disabled(settingsViewModel.getAPIKey(for: "Google").isEmpty)
            }

            // Anthropic API Key
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Anthropic API Key")
                        .fontWeight(.medium)
                    Spacer()
                    if !settingsViewModel.getAPIKey(for: "Anthropic").isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                SecureField("sk-ant-...", text: Binding(
                    get: { settingsViewModel.getAPIKey(for: "Anthropic") },
                    set: { settingsViewModel.updateAPIKey(for: "Anthropic", key: $0) }
                ))
                #if os(macOS)
                .textFieldStyle(.squareBorder)
                #else
                .textFieldStyle(.roundedBorder)
                #endif
                .font(.system(.body, design: .monospaced))

                Button("测试并获取模型") {
                    // TODO: 实现Anthropic API测试
                }
                .buttonStyle(.bordered)
                .disabled(settingsViewModel.getAPIKey(for: "Anthropic").isEmpty)
            }
        }
    }
    


}



// MARK: - macOS 专用 Section 视图
#if os(macOS)
struct SectionView<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding()
            .background(Color(.windowBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
        }
    }
}
#endif

// MARK: - 预览
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let mainViewModel = MainViewModel()
        let settingsViewModel = SettingsViewModel(mainViewModel: mainViewModel)

        SettingsView(
            settingsViewModel: settingsViewModel,
            mainViewModel: mainViewModel
        )
    }
}
