//
//  DocumentPickerCoordinator.swift
//  PrintStoreClient
//
//  Created by May on 4.02.25.
//
import UIKit

final class DocumentPickerCoordinator: NSObject {
    private weak var vievController: UIViewController?
    private let onFileSelected: (URL) -> Void
    private let onError: (Error) -> Void
    
    init(
        viewController: UIViewController?,
        onFileSelected: @escaping (URL) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.vievController = viewController
        self.onFileSelected = onFileSelected
        self.onError = onError
    }
    
    func presentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        vievController?.present(picker, animated: true)
    }
}

extension DocumentPickerCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            onError(SceneError.invalidFile)
            return
        }
        
        onFileSelected(url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // will write canclellation here later
    }
}
