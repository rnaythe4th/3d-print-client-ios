//
//  FilePickerService.swift
//  PrintStoreClient
//
//  Created by May on 6.02.25.
//
import UIKit
import UniformTypeIdentifiers

enum FilePickerError: Error, LocalizedError {
    case noFileSelected
    case cancelled
    case cannotAccessFile
    
    var errorDescription: String? {
        switch self {
        case .noFileSelected:
            return "File not selected."
        case .cancelled:
            return "Cancelled file selection"
        case .cannotAccessFile:
            return "Cannot access the file"
        }
    }
}

final class FilePickerService: NSObject, UIDocumentPickerDelegate {
    var completion: ((Result<URL, Error>) -> Void)?
    
    func pickFile(from viewController: UIViewController,
                  completion: @escaping ((Result<URL, Error>) -> Void)
    ) {
        self.completion = completion
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        viewController.present(documentPicker, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else {
            completion?(.failure(FilePickerError.noFileSelected))
            completion = nil
            return
        }
        
        if fileURL.startAccessingSecurityScopedResource() {
            completion?(.success(fileURL))
            fileURL.stopAccessingSecurityScopedResource()
        } else {
            completion?(.failure(FilePickerError.cannotAccessFile))
        }
        completion = nil
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion?(.failure(FilePickerError.cancelled))
        completion = nil
    }
}
