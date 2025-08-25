import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - 自适应文本编辑器
struct AdaptiveTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let fontSize: CGFloat
    let onCommit: () -> Void
    
    @State private var calculatedHeight: CGFloat = 36
    @FocusState private var isFocused: Bool
    
    #if os(iOS)
    private let font = UIFont.systemFont(ofSize: 16)
    private let textEditorPadding = 0.0
    #elseif os(macOS)
    private let font = NSFont.systemFont(ofSize: 16)
    private let textEditorPadding = 8.0
    #endif
    
    private let padding: CGFloat = 16
    
    init(
        text: Binding<String>,
        placeholder: String = "输入消息...",
        minHeight: CGFloat = 36,
        maxHeight: CGFloat = 120,
        fontSize: CGFloat = 16,
        onCommit: @escaping () -> Void = {}
    ) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.fontSize = fontSize
        self.onCommit = onCommit
        self._calculatedHeight = State(initialValue: minHeight)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // 占位符
                if text.isEmpty && !isFocused{
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .font(.system(size: fontSize))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                
                // TextEditor
                TextEditor(text: $text)
                    .font(.system(size: fontSize))
                    .focused($isFocused)
                    .background(Color.clear)
                    .onChange(of: text, { oldValue, newValue in
                        updateTextHeight(for: geometry.size.width)
                        // 确保新内容可见 - 延迟执行避免冲突
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            updateTextHeight(for: geometry.size.width)
                        }
                    })
                    .onAppear {
                        updateTextHeight(for: geometry.size.width)
                    }
                    .onChange(of: isFocused, { oldValue, newValue in
                        if newValue && !text.isEmpty {
                            // 获得焦点时确保内容可见
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                updateTextHeight(for: geometry.size.width)
                            }
                        }
                    })
                    .onSubmit {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onCommit()
                        }
                    }
                    .padding(textEditorPadding)
                    .scrollContentBackground(.hidden)
            }
        }
        .frame(
            minHeight: minHeight,
            maxHeight: min(calculatedHeight, maxHeight)
        )
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            isFocused = true
        }
    }
    
    private func updateTextHeight(for width: CGFloat) {
        guard !text.isEmpty else {
            calculatedHeight = minHeight
            return
        }
        
        #if os(iOS)
        let boundingRect = text.boundingRect(
            with: CGSize(width: width - padding, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        #elseif os(macOS)
        let boundingRect = text.boundingRect(
            with: CGSize(width: width - padding, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        #endif
        
        let newHeight = max(minHeight, boundingRect.height + padding)
        if abs(calculatedHeight - newHeight) > 2 {
            calculatedHeight = newHeight
        }
    }
}



// MARK: - 预览
struct AdaptiveTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 空文本状态
            AdaptiveTextEditor(
                text: .constant(""),
                placeholder: "输入消息..."
            ) {
                print("发送消息")
            }
            .padding()
            
            // 短文本状态
            AdaptiveTextEditor(
                text: .constant("Hello World!"),
                placeholder: "输入消息..."
            ) {
                print("发送消息")
            }
            .padding()
            
            // 长文本状态
            AdaptiveTextEditor(
                text: .constant("这是一条长消息，用来测试文本编辑器的自适应高度功能。当文本内容较多时，编辑器应该自动调整高度，但不超过最大高度限制。支持多行输入和自动换行。"),
                placeholder: "输入消息..."
            ) {
                print("发送消息")
            }
            .padding()
            
            Spacer()
        }
        .background(Color.secondary.opacity(0.1))
    }
}
