//
//  ViewController.swift
//  PrintStoreClient
//
//  Created by May on 28.01.25.
//

import UIKit

class ViewController: UIViewController {
    
    // Text field to allow user to enter server address
    private let serverAddressTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter server address"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    // button for selecting file from storage
    private let selectFileButton: UIButton = {
        let button = UIButton()
        button.setTitle("Select file", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // upload to server button
    private let uploadButton: UIButton = {
        let button = UIButton()
        button.setTitle("Upload to server", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // result from server Label
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "Print cost: "
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var selectedFileURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        
        view.backgroundColor = .white
        
        view.addSubview(serverAddressTextField)
        view.addSubview(selectFileButton)
        view.addSubview(uploadButton)
        view.addSubview(resultLabel)
        
        NSLayoutConstraint.activate([
            serverAddressTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            serverAddressTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            serverAddressTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            selectFileButton.topAnchor.constraint(equalTo: serverAddressTextField.bottomAnchor, constant: 20),
            selectFileButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            selectFileButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            uploadButton.topAnchor.constraint(equalTo: selectFileButton.bottomAnchor, constant: 20),
            uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            uploadButton.heightAnchor.constraint(equalToConstant: 44),
            
            resultLabel.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 20),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupActions() {
        selectFileButton.addTarget(self, action: #selector(selectFile), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(uploadFile), for: .touchUpInside)
    }
    
    @objc private func selectFile() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        documentPicker.delegate = self
        // temporary false
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    @objc private func uploadFile() {
        guard let serverURLString = serverAddressTextField.text,
              let serverURL = URL(string: serverURLString),
              let fileURL = selectedFileURL else {
            showAlert(message: "Check server address and try again")
            return
        }
        
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        
        // multipart/form-data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // add file to request body
        do {
            let fileData = try Data(contentsOf: fileURL)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"uploaded_file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            showAlert(message: "Ошибка чтения файла: \(error.localizedDescription)")
            return
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // send request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                self?.showAlert(message: "Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                self?.showAlert(message: "Response contains no data")
                return
            }
            
            // parse JSON
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let materialUsed = json["materialUsed"] as? String {
                    DispatchQueue.main.async {
                        self?.resultLabel.text = "Material used: \(materialUsed)"
                    }
                } else {
                    self?.showAlert(message: "Invalid JSON format")
                }
            } catch {
                self?.showAlert(message: "Error parsing JSON: \(error.localizedDescription)")
            }
            
        }
        task.resume()
    }
    
    // alerts method
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction((UIAlertAction(title: "OK", style: .default)))
            self.present(alert, animated: true)
        }
    }

}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }
        selectedFileURL = fileURL
    }
}

