import SwiftUI

#if os(iOS)
import PhotosUI
#endif

// MARK: - 附件按钮
struct AttachmentButton: View {
    let onImageSelected: () -> Void
    let onFileSelected: () -> Void
    let isEnabled: Bool
    
    @State private var showingActionSheet = false
    @State private var showingImagePicker = false
    @State private var showingFilePicker = false
    
    init(
        isEnabled: Bool = true,
        onImageSelected: @escaping () -> Void = {},
        onFileSelected: @escaping () -> Void = {}
    ) {
        self.isEnabled = isEnabled
        self.onImageSelected = onImageSelected
        self.onFileSelected = onFileSelected
    }
    
    var body: some View {
        Button(action: {
            showingActionSheet = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isEnabled ? .primary : .secondary)
                .frame(width: 36, height: 36)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
        }
        .disabled(!isEnabled)
        #if os(iOS)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("添加附件"),
                message: Text("选择要添加的内容类型"),
                buttons: [
                    .default(Text("📷 选择图片")) {
                        showingImagePicker = true
                    },
                    .default(Text("📄 选择文件")) {
                        showingFilePicker = true
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
        #else
        .confirmationDialog("添加附件", isPresented: $showingActionSheet) {
            Button("📷 选择图片") {
                showingImagePicker = true
            }
            Button("📄 选择文件") {
                showingFilePicker = true
            }
            Button("取消", role: .cancel) { }
        }
        #endif
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView { _ in
                onImageSelected()
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            FilePickerView { _ in
                onFileSelected()
            }
        }
    }
}

// MARK: - 图片选择器
private struct ImagePickerView: View {
    let onImageSelected: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        #if os(iOS)
        ImagePickerWrapper(onImageSelected: onImageSelected, dismiss: dismiss)
        #elseif os(macOS)
        MacImagePickerView(onImageSelected: onImageSelected, dismiss: dismiss)
        #endif
    }
}

// MARK: - 文件选择器
private struct FilePickerView: View {
    let onFileSelected: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        #if os(iOS)
        FilePickerWrapper(onFileSelected: onFileSelected, dismiss: dismiss)
        #elseif os(macOS)
        MacFilePickerView(onFileSelected: onFileSelected, dismiss: dismiss)
        #endif
    }
}

// MARK: - iOS 图片选择器包装
#if os(iOS)
private struct ImagePickerWrapper: UIViewControllerRepresentable {
    let onImageSelected: (URL) -> Void
    let dismiss: DismissAction
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerWrapper
        
        init(_ parent: ImagePickerWrapper) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        // TODO: 保存图片并返回URL
                        // 这里需要实现图片保存逻辑
                        DispatchQueue.main.async {
                            // 临时URL，实际使用时需要保存到临时目录
                            if let data = image.jpegData(compressionQuality: 0.8) {
                                let tempURL = FileManager.default.temporaryDirectory
                                    .appendingPathComponent(UUID().uuidString)
                                    .appendingPathExtension("jpg")
                                
                                do {
                                    try data.write(to: tempURL)
                                    self.parent.onImageSelected(tempURL)
                                } catch {
                                    print("保存图片失败: \(error)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct FilePickerWrapper: UIViewControllerRepresentable {
    let onFileSelected: (URL) -> Void
    let dismiss: DismissAction
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePickerWrapper
        
        init(_ parent: FilePickerWrapper) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.dismiss()
            
            if let url = urls.first {
                parent.onFileSelected(url)
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
#endif

// MARK: - macOS 选择器
#if os(macOS)
private struct MacImagePickerView: View {
    let onImageSelected: (URL) -> Void
    let dismiss: DismissAction
    
    var body: some View {
        VStack {
            Text("选择图片")
                .font(.headline)
                .padding()
            
            Button("选择图片文件") {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.image]
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.canChooseFiles = true
                
                if panel.runModal() == .OK {
                    if let url = panel.url {
                        onImageSelected(url)
                    }
                }
                dismiss()
            }
            .padding()
            
            Button("取消") {
                dismiss()
            }
            .padding()
        }
        .frame(width: 300, height: 200)
    }
}

private struct MacFilePickerView: View {
    let onFileSelected: (URL) -> Void
    let dismiss: DismissAction
    
    var body: some View {
        VStack {
            Text("选择文件")
                .font(.headline)
                .padding()
            
            Button("选择文件") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.canChooseFiles = true
                
                if panel.runModal() == .OK {
                    if let url = panel.url {
                        onFileSelected(url)
                    }
                }
                dismiss()
            }
            .padding()
            
            Button("取消") {
                dismiss()
            }
            .padding()
        }
        .frame(width: 300, height: 200)
    }
}
#endif

// MARK: - 预览
struct AttachmentButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            AttachmentButton(
                onImageSelected: {
                    print("选择了图片")
                },
                onFileSelected: {
                    print("选择了文件")
                }
            )
            
            AttachmentButton(
                isEnabled: false,
                onImageSelected: {
                    print("选择了图片")
                },
                onFileSelected: {
                    print("选择了文件")
                }
            )
        }
        .padding()
    }
}
