import SwiftUI

// MARK: - 聊天主视图
struct ChatView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    @ObservedObject var mainViewModel: MainViewModel
    
    // 移除不必要的ScrollViewReader状态
    
    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            MessageListView(
                messages: chatViewModel.messages,
                isLoading: chatViewModel.isLoading,
                onDeleteMessage: chatViewModel.deleteMessage,
                onResendMessage: chatViewModel.resendMessage,
                onStartEditingMessage: chatViewModel.startEditingMessage,
                onSaveEditedMessage: chatViewModel.saveEditedMessage,
                onCancelEditingMessage: chatViewModel.cancelEditingMessage
            )
            
            // 输入区域
            InputAreaView(
                text: $chatViewModel.inputText,
                canSend: chatViewModel.canSend,
                canRegenerate: chatViewModel.canRegenerate,
                isLoading: chatViewModel.isLoading,
                onSend: chatViewModel.sendMessage,
                onRegenerate: chatViewModel.regenerateLastResponse,
                onImageSelected: chatViewModel.addImage,
                onFileSelected: chatViewModel.addFile
            )
        }
        .onChange(of: mainViewModel.currentSession) { _, session in
            if let session = session {
                chatViewModel.setCurrentSession(session)
            }
        }
        .onAppear {
            if let session = mainViewModel.currentSession {
                chatViewModel.setCurrentSession(session)
            }
        }
    }
}

// MARK: - 预览
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let mainViewModel = MainViewModel()
        let chatViewModel = ChatViewModel(mainViewModel: mainViewModel)
        
        ChatView(
            chatViewModel: chatViewModel,
            mainViewModel: mainViewModel
        )
    }
}
