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
    private var selectedFileURL: URL?
    private let viewModel: PrintViewModel
    private var cancellables = Set<AnyCancellable>()
    private let filePickerService = FilePickerService()
    private var currentIPAddress: String?
    private var zoomTransitioningDelegate: ZoomOutTransitionDelegate?
    
    init(viewModel: PrintViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    
    private let previewPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Select a model for preview"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupScene()
        bindViewModel()
        //        serverAddressTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: currentIPAddress ?? "Select IP",
            style: .plain,
            target: self,
            action: #selector(showIPAddressPicker)
        )
        
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
        filePickerService.pickFile(from: self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let fileURL):
                    print("File selected at url: \(fileURL)")
                    self.selectedFileURL = fileURL
                case .failure(let error):
                    self.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func uploadFile() {
        resultActivityIndicator.startAnimating()
        costActivityIndicator.startAnimating()
        
        guard let fileURL = selectedFileURL else {
            showAlert(message: "File not selected")
            return
        }
        
        guard let ip = currentIPAddress,
              !ip.isEmpty,
              let serverURL = URL(string: ip) else {
            showAlert(message: "Server IP not selected or invalid")
            return
        }
        
        Task {
            do {
                let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
                try await viewModel.uploadFile(
                    serverAddress: (ip + ":4000/slice"),
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
        
        //        view.addSubview(serverAddressTextField)
        view.addSubview(selectFileButton)
        view.addSubview(uploadButton)
        view.addSubview(resultLabel)
        view.addSubview(printCostLabel)
        view.addSubview(previewContainer)
        previewContainer.addSubview(sceneView)
        previewContainer.addSubview(previewPlaceholderLabel)
        view.addSubview(resultActivityIndicator)
        view.addSubview(costActivityIndicator)
        
        NSLayoutConstraint.activate([
            
            // "Select File" button
            selectFileButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
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
            costActivityIndicator.leadingAnchor.constraint(equalTo: printCostLabel.trailingAnchor, constant: 8),
            
            previewPlaceholderLabel.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            previewPlaceholderLabel.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor)
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
    
    @objc private func showIPAddressPicker() {
        let ipPickerVC = IPAddressPickerView()
        ipPickerVC.delegate = self
        
        let nav = UINavigationController(rootViewController: ipPickerVC)
        
        // custom animation
        nav.modalPresentationStyle = .custom
        
        // create transition delegate
        let transitionDelegate = ZoomOutTransitionDelegate()
        self.zoomTransitioningDelegate = transitionDelegate
        nav.transitioningDelegate = transitionDelegate
        //nav.modalPresentationStyle = .popover
        present(nav, animated: true)
    }
}

extension PrintViewController: IPAddressPickerDelegate {
    func didSelectIPAddress(_ ip: String) {
        self.currentIPAddress = ip
        navigationItem.rightBarButtonItem?.title = ip
    }
}
