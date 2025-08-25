//
//  ContentView.swift
//  EchoChat
//
//  Created by 刘喆 on 2025-08-23.
//

import SwiftUI
import SwiftData

// MARK: - 主内容视图
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var mainViewModel = MainViewModel()
    
    var body: some View {
        MainView(mainViewModel: mainViewModel)
            .preferredColorScheme(nil) // 支持系统自动切换深浅模式
            .onAppear {
                mainViewModel.setModelContext(modelContext)
            }
    }
}

// MARK: - 预览
#Preview {
    ContentView()
}
