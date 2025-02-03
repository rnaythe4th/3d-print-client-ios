//
//  PrintViewController.swift
//  PrintStoreClient
//
//  Created by May on 29.01.25.
//

import UIKit
import SceneKit
import Combine

class PrintViewController: UIViewController, UITextFieldDelegate {
    
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
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            
            config.baseBackgroundColor = .clear
            config.baseForegroundColor = .systemBlue
            config.background.strokeColor = .systemBlue
            config.background.strokeWidth = 1
            config.background.cornerRadius = 8
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            
            button.configuration = config
        } else {
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemBlue.cgColor
            button.layer.cornerRadius = 8
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        }
        
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
    
    private let printCostLabel: UILabel = {
        let label = UILabel()
        label.text = "Print cost: "
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let sceneView: SCNView = {
        let view = SCNView()
        view.backgroundColor = .clear
        view.autoenablesDefaultLighting = true
        view.allowsCameraControl = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let resultActivityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    private let costActivityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    private var selectedFileURL: URL?
    private var viewModel = PrintViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupScene()
        bindViewModel()
        serverAddressTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        viewModel.state = .idle
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // ViewModel -> View
    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .idle:
                    self.resultLabel.text = "Material used: "
                    self.printCostLabel.text = "Print cost: "
                    self.resultActivityIndicator.stopAnimating()
                    self.costActivityIndicator.stopAnimating()
                case .loading:
                    self.resultActivityIndicator.startAnimating()
                    self.costActivityIndicator.startAnimating()
                case .success(let materialUsed, let printCost):
                    self.resultLabel.text = materialUsed
                    self.printCostLabel.text = printCost
                    self.resultActivityIndicator.stopAnimating()
                    self.costActivityIndicator.stopAnimating()
                case .error(let message):
                    self.showAlert(message: message)
                    self.resultActivityIndicator.stopAnimating()
                    self.costActivityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }
    
    @objc private func selectFile() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        documentPicker.delegate = self
        // temporary false
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    @objc private func uploadFile() {
        resultActivityIndicator.startAnimating()
        costActivityIndicator.startAnimating()
        
        guard let fileURL = selectedFileURL else {
            showAlert(message: "File not selected")
            return
        }
        
        //        if fileURL.startAccessingSecurityScopedResource() {
        //            defer { fileURL.stopAccessingSecurityScopedResource() }
        
        
        Task {
            do {
                let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
                try await viewModel.uploadFile(
                    serverAddress: serverAddressTextField.text,
                    fileURL: fileURL
                )
            } catch {
                await MainActor.run {
                    showAlert(message: error.localizedDescription)
                    resultActivityIndicator.stopAnimating()
                    costActivityIndicator.stopAnimating()
                }
            }
        }
        
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(serverAddressTextField)
        view.addSubview(selectFileButton)
        view.addSubview(uploadButton)
        view.addSubview(resultLabel)
        view.addSubview(printCostLabel)
        view.addSubview(previewContainer)
        previewContainer.addSubview(sceneView)
        view.addSubview(resultActivityIndicator)
        view.addSubview(costActivityIndicator)
        
        NSLayoutConstraint.activate([
            
            // server address Text Field
            serverAddressTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            serverAddressTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            serverAddressTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // "Select File" button
            selectFileButton.topAnchor.constraint(equalTo: serverAddressTextField.bottomAnchor, constant: 20),
            selectFileButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // "Upload to server" button
            uploadButton.topAnchor.constraint(equalTo: selectFileButton.bottomAnchor, constant: 20),
            uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            uploadButton.heightAnchor.constraint(equalToConstant: 44),
            
            // "Filament used" label
            resultLabel.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 20),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            //resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // "Print cost" label
            printCostLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 10),
            printCostLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            //printCostLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 3D-Model preview container
            previewContainer.topAnchor.constraint(equalTo: printCostLabel.bottomAnchor, constant: 20),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Scene view inside previewContainer
            // *** same as parent ***
            sceneView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            
            // loading animation for Filament used
            resultActivityIndicator.centerYAnchor.constraint(equalTo: resultLabel.centerYAnchor),
            resultActivityIndicator.leadingAnchor.constraint(equalTo: resultLabel.trailingAnchor, constant: 8),
            // loading animation for Print cost
            costActivityIndicator.centerYAnchor.constraint(equalTo: printCostLabel.centerYAnchor),
            costActivityIndicator.leadingAnchor.constraint(equalTo: printCostLabel.trailingAnchor, constant: 8)
        ])
    }
    
    private func setupActions() {
        selectFileButton.addTarget(self, action: #selector(selectFile), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(uploadFile), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(animateButtonPress(_:)), for: .touchDown)
        uploadButton.addTarget(self, action: #selector(animateButtonRelease(_:)), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }
    
    private func setupScene() {
        let scene = SCNScene()
        sceneView.scene = scene
        // Camera setup
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 15)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    // alerts method
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction((UIAlertAction(title: "OK", style: .default)))
            self.present(alert, animated: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Закрыть клавиатуру
        return true
    }
    
    @objc private func animateButtonPress(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        })
    }
    
    @objc private func animateButtonRelease(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, animations: {
            sender.transform = .identity
        })
    }
    
    private func startLoading() {
        resultActivityIndicator.startAnimating()
        costActivityIndicator.startAnimating()
    }
    
    
    
}

extension PrintViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }
        print("Selected file: \(fileURL)")
        selectedFileURL = fileURL
        
        // close documentPicker automatically after selection is done
        dismiss(animated: true) { [weak self] in
            // avoid access issues
            if fileURL.startAccessingSecurityScopedResource() {
                self?.loadModel(from: fileURL)
                fileURL.stopAccessingSecurityScopedResource()
            } else {
                self?.showAlert(message: "Error accessing the file")
            }
        }
    }
    
    private func loadModel(from url: URL) {
        do {
            // Delete already loaded model
            sceneView.scene?.rootNode.childNodes.forEach { $0.removeFromParentNode() }
            
            // Load new model
            print("Attempt to load model: \(url.path)")
            let scene = try SCNScene(url: url, options: nil)
            print("Model successfully loaded")
            for node in scene.rootNode.childNodes {
                applyMaterialColor(UIColor.green, to: node)
                sceneView.scene?.rootNode.addChildNode(node)
            }
            
            // auto-scaling
            let (min, max) = sceneView.scene!.rootNode.boundingBox
            let size = SCNVector3(max.x - min.x, max.y - min.y, max.z - min.z)
            let maxSize = Swift.max(size.x, size.y, size.z)
            // set scale
            let scale = Float(5.0 / maxSize)
            
            sceneView.scene?.rootNode.childNodes.forEach {
                $0.scale = SCNVector3(scale, scale, scale)
            }
            
        } catch {
            print("Error loading model: \(error.localizedDescription)")
            showAlert(message: "Error loading model: \(error.localizedDescription)")
        }
    }
    
    private func applyMaterialColor(_ color: UIColor, to node: SCNNode) {
        let coloredMaterial = SCNMaterial()
        coloredMaterial.diffuse.contents = color
        
        node.geometry?.materials = [coloredMaterial]
        
        for child in node.childNodes {
            applyMaterialColor(color, to: child)
        }
    }
    
    /*
     private var rotationAngle: Float = { return 0 }
     
     private func startRotation() {
     sceneView.scene?.rootNode.childNodes.forEach { node in
     let rotation = SCNAction.rotateBy(x: -, y: 2, z: -, duration: 10)
     let repeatRotation = SCNAction.repeatForever(rotation)
     node.runAction(repeatRotation)
     }
     }
     */
}
