//
//  PrintViewController.swift
//  PrintStoreClient
//
//  Created by May on 29.01.25.
//

import UIKit
import SceneKit
import Combine

class PrintViewController: UIViewController {
    
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
        label.text = "Print cost: *upload file first*"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let printCostLabel: UILabel = {
        let label = UILabel()
        label.text = "Print cost: *upload file first*"
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
    
    private var selectedFileURL: URL?
    private var viewModel = PrintViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupScene()
        bindViewModel()
    }
    
    // ViewModel -> View
    private func bindViewModel() {
        viewModel.$materialUsedText
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: printCostLabel)
            .store(in: &cancellables)
        
        viewModel.$printCostText
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: printCostLabel)
            .store(in: &cancellables)
        
        viewModel.$showAlert
            .filter { $0.isShown }
            .sink { [weak self] alert in
                self?.showAlert(message: alert.message)
                self?.viewModel.showAlert = (message: "", isShown: false)
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
        viewModel.uploadFile(serverAddress: serverAddressTextField.text,
                             fileURL: selectedFileURL)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(serverAddressTextField)
        view.addSubview(selectFileButton)
        view.addSubview(uploadButton)
        view.addSubview(resultLabel)
        view.addSubview(printCostLabel)
        view.addSubview(previewContainer)
        previewContainer.addSubview(sceneView)
        
        NSLayoutConstraint.activate([
            
            // server address Text Field
            serverAddressTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            serverAddressTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            serverAddressTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // "Select File" button
            selectFileButton.topAnchor.constraint(equalTo: serverAddressTextField.bottomAnchor, constant: 20),
            selectFileButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            selectFileButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // "Upload to server" button
            uploadButton.topAnchor.constraint(equalTo: selectFileButton.bottomAnchor, constant: 20),
            uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            uploadButton.heightAnchor.constraint(equalToConstant: 44),
            
            // "Filament used" label
            resultLabel.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 20),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // "Print cost" label
            printCostLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 10),
            printCostLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            printCostLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
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
            sceneView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor)
        ])
    }
    
    private func setupActions() {
        selectFileButton.addTarget(self, action: #selector(selectFile), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(uploadFile), for: .touchUpInside)
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
    
}

extension PrintViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }
        selectedFileURL = fileURL
        
        // close documentPicker automatically after selection is done
        dismiss(animated: true) { [weak self] in
            self?.loadModel(from: fileURL)
        }
    }
    
    private func loadModel(from url: URL) {
        do {
            // Delete already loaded model
            sceneView.scene?.rootNode.childNodes.forEach { $0.removeFromParentNode() }
            
            // Load new model
            let scene = try SCNScene(url: url, options: nil)
            for node in scene.rootNode.childNodes {
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
            showAlert(message: "Error loading model: \(error.localizedDescription)")
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
