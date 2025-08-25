import Foundation
import SwiftUI
import SwiftData

// MARK: - 历史记录视图模型
@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var filteredSessions: [ChatSession] = []
    @Published var isSearching: Bool = false
    
    // MARK: - Data Source
    weak var mainViewModel: MainViewModel?
    var modelContext: ModelContext? { mainViewModel?.modelContext }
    private var allSessions: [ChatSession] = []
    
    // MARK: - Initialization
    init(mainViewModel: MainViewModel? = nil) {
        self.mainViewModel = mainViewModel
        setupSearchObserver()
    }
    
    // MARK: - Data Management
    func loadSessions(_ sessions: [ChatSession]) {
        allSessions = sessions
        updateFilteredSessions()
    }
    
    func refresh() {
        loadSessionsFromSwiftData()
    }
    
    private func loadSessionsFromSwiftData() {
        guard let context = modelContext else { 
            // 如果没有 context，回退到从 mainViewModel 获取
            guard let mainViewModel = mainViewModel else { return }
            loadSessions(mainViewModel.sessions)
            return
        }
        
        do {
            let descriptor = FetchDescriptor<ChatSession>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            let sessions = try context.fetch(descriptor)
            loadSessions(sessions)
        } catch {
            print("从 SwiftData 加载历史会话失败: \(error)")
            allSessions = []
            updateFilteredSessions()
        }
    }
    
    // MARK: - Search Management
    func updateSearchText(_ text: String) {
        searchText = text
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Session Actions
    func selectSession(_ session: ChatSession) {
        mainViewModel?.selectSession(session)
    }
    
    func deleteSession(_ session: ChatSession) {
        mainViewModel?.deleteSession(session)
        refresh()
    }
    
    func duplicateSession(_ session: ChatSession) {
        // TODO: 实现会话复制功能
        // 预留给您后续开发
    }
    
    func exportSession(_ session: ChatSession) {
        // TODO: 实现会话导出功能
        // 预留给您后续开发
    }
    
    // MARK: - Computed Properties
    var hasSearchResults: Bool {
        return !searchText.isEmpty && !filteredSessions.isEmpty
    }
    
    var hasNoSearchResults: Bool {
        return !searchText.isEmpty && filteredSessions.isEmpty
    }
    
    var groupedSessions: [SessionGroup] {
        return groupSessionsByDate(filteredSessions)
    }
    
    // MARK: - Private Methods
    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateFilteredSessions()
            }
            .store(in: &cancellables)
    }
    
    private func updateFilteredSessions() {
        let searchQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if searchQuery.isEmpty {
            filteredSessions = allSessions
            isSearching = false
        } else {
            filteredSessions = allSessions.filter { session in
                session.title.lowercased().contains(searchQuery) ||
                session.selectedModel.lowercased().contains(searchQuery)
            }
            isSearching = true
        }
    }
    
    private func groupSessionsByDate(_ sessions: [ChatSession]) -> [SessionGroup] {
        let calendar = Calendar.current
        let now = Date()
        
        let grouped = Dictionary(grouping: sessions) { session in
            if calendar.isDateInToday(session.updatedAt) {
                return "今天"
            } else if calendar.isDateInYesterday(session.updatedAt) {
                return "昨天"
            } else if calendar.isDate(session.updatedAt, equalTo: now, toGranularity: .weekOfYear) {
                return "本周"
            } else if calendar.isDate(session.updatedAt, equalTo: now, toGranularity: .month) {
                return "本月"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "zh_CN")
                formatter.dateFormat = "yyyy年MM月"
                return formatter.string(from: session.updatedAt)
            }
        }
        
        let sortedGroups = grouped.map { (key, value) in
            SessionGroup(
                title: key,
                sessions: value.sorted { $0.updatedAt > $1.updatedAt }
            )
        }.sorted { group1, group2 in
            // 自定义排序：今天 > 昨天 > 本周 > 本月 > 其他（按时间倒序）
            let order = ["今天", "昨天", "本周", "本月"]
            let index1 = order.firstIndex(of: group1.title) ?? Int.max
            let index2 = order.firstIndex(of: group2.title) ?? Int.max
            
            if index1 != Int.max || index2 != Int.max {
                return index1 < index2
            } else {
                return group1.title > group2.title
            }
        }
        
        return sortedGroups
    }
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Supporting Types
struct SessionGroup: Identifiable {
    let id = UUID()
    let title: String
    let sessions: [ChatSession]
}

// MARK: - Combine Import
import Combine
