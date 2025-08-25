//
//  EchoChatApp.swift
//  EchoChat
//
//  Created by 刘喆 on 2025-08-23.
//

import SwiftUI
import SwiftData

@main
struct EchoChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ChatSession.self, ChatMessage.self])
    }
}