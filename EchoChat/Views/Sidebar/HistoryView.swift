import SwiftUI
import SwiftData

// MARK: - 历史记录侧栏视图
struct HistoryView: View {
    @ObservedObject var historyViewModel: HistoryViewModel
    @ObservedObject var mainViewModel: MainViewModel
    
    // 使用 @Query 自动监听 SwiftData 变化
    @Query(sort: \ChatSession.updatedAt, order: .reverse) 
    private var allSessions: [ChatSession]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                searchBar
                
                // 历史列表
                historyList
            }
            .navigationTitle("历史对话")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        mainViewModel.isHistoryPresented = false
                    }
                }
            }
        }
        .onAppear {
            // 使用 @Query 数据源更新 HistoryViewModel
            historyViewModel.loadSessions(allSessions)
        }
        .onChange(of: allSessions) { _, newSessions in
            // 当 SwiftData 数据变化时自动更新
            historyViewModel.loadSessions(newSessions)
        }
    }
    
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索对话...", text: $historyViewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !historyViewModel.searchText.isEmpty {
                    Button(action: historyViewModel.clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var historyList: some View {
        Group {
            if historyViewModel.hasNoSearchResults {
                noResultsView
            } else {
                List {
                    ForEach(historyViewModel.groupedSessions) { group in
                        Section(header: sectionHeader(group.title)) {
                            ForEach(group.sessions) { session in
                                HistoryItemView(
                                    session: session,
                                    isSelected: mainViewModel.currentSession?.id == session.id,
                                    onTap: {
                                        historyViewModel.selectSession(session)
                                        mainViewModel.isHistoryPresented = false
                                    },
                                    onDelete: {
                                        historyViewModel.deleteSession(session)
                                    }
                                )
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("未找到相关对话")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("尝试使用不同的关键词搜索")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 预览
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let mainViewModel = MainViewModel()
        let historyViewModel = HistoryViewModel(mainViewModel: mainViewModel)
        
        HistoryView(
            historyViewModel: historyViewModel,
            mainViewModel: mainViewModel
        )
    }
}
