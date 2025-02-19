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
    
    private let accentColor = UIColor(red: 0.10, green: 0.46, blue: 0.82, alpha: 1.00)
    private let lightAccent = UIColor(red: 0.10, green: 0.46, blue: 0.82, alpha: 0.15)
    
    // button for selecting file from storage
    private lazy var selectFileButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Select File"
        config.image = UIImage(systemName: "folder")
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.baseBackgroundColor = lightAccent
        config.baseForegroundColor = accentColor
        config.background.cornerRadius = 14
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        button.configuration = config
        button.applyShadow(opacity: 0.1, radius: 8)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    // upload to server button
    private lazy var uploadButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Calculate Print Cost"
        config.baseBackgroundColor = accentColor
        config.baseForegroundColor = .white
        config.background.cornerRadius = 14
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17, weight: .semibold)
            return outgoing
        }
        button.configuration = config
        button.applyShadow(opacity: 0.2, radius: 10)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var infoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private func createInfoRow(title: String) -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 8
        rowStack.alignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        
        let valueStack = UIStackView()
        valueStack.axis = .horizontal
        valueStack.spacing = 8
        
        let valueLabel = UILabel()
        valueLabel.text = "-"
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = .label
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = accentColor
        spinner.hidesWhenStopped = true
        spinner.tag = 100 // Для идентификации
        
        valueStack.addArrangedSubview(valueLabel)
        valueStack.addArrangedSubview(spinner)
        
        rowStack.addArrangedSubview(titleLabel)
        rowStack.addArrangedSubview(valueStack)
        return rowStack
    }
    
    private let previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.applyShadow(
            opacity: 0.5,
            radius: 50,
            offset: CGSize(width: 0, height: 16),
            color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = false
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
    
//    private lazy var loadingIndicator: UIActivityIndicatorView = {
//        let spinner = UIActivityIndicatorView(style: .medium)
//        spinner.color = accentColor
//        spinner.hidesWhenStopped = true
//        spinner.translatesAutoresizingMaskIntoConstraints = false
//        return spinner
//    }()
    
    private let previewPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Select a 3D Model to Preview"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(red: 0.80, green: 0.80, blue: 0.80, alpha: 1)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ipAddressButton: UIButton = {
        let button = UIButton()
        button.setTitle("Select IP", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = .clear
            config.baseForegroundColor = .systemBlue
            //config.background.strokeColor = .systemBlue
            //config.background.strokeWidth = 1
            //config.background.cornerRadius = 8
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            button.configuration = config
        } else {
            //button.layer.borderWidth = 1
            //button.layer.borderColor = UIColor.systemBlue.cgColor
            //button.layer.cornerRadius = 8
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(settingsButtonTapped))
        navigationItem.leftBarButtonItem = settingsButton
        
        viewModel.state = .idle
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewContainer.layer.shadowPath = UIBezierPath(
            roundedRect: previewContainer.bounds,
            cornerRadius: previewContainer.layer.cornerRadius
        ).cgPath
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
                
                guard let materialRow = self.infoStack.arrangedSubviews[0] as? UIStackView,
                      let costRow = self.infoStack.arrangedSubviews[1] as? UIStackView,
                      let materialSpinner = materialRow.viewWithTag(100) as? UIActivityIndicatorView,
                      let costSpinner = costRow.viewWithTag(100) as? UIActivityIndicatorView,
                      let materialLabel = (materialRow.arrangedSubviews[1] as? UIStackView)?.arrangedSubviews[0] as? UILabel,
                      let costLabel = (costRow.arrangedSubviews[1] as? UIStackView)?.arrangedSubviews[0] as? UILabel else { return }
                
                switch state {
                case .idle:
                    self.updateInfoLabels(material: "-", cost: "-")
                    materialSpinner.stopAnimating()
                    costSpinner.stopAnimating()
                case .loading:
                    materialSpinner.startAnimating()
                    costSpinner.startAnimating()
                    materialLabel.text = "Calculating..."
                    costLabel.text = "Calculating..."
                case .success(let materialUsed, let printCost):
                    materialLabel.text = materialUsed
                    costLabel.text = printCost
                    materialSpinner.stopAnimating()
                    costSpinner.stopAnimating()
                case .error(let message):
                    self.showAlert(message: message)
                    materialSpinner.stopAnimating()
                    costSpinner.stopAnimating()
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
                    self.loadModel(from: fileURL)
                case .failure(let error):
                    self.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func loadModel(from fileURL: URL) {
        guard fileURL.startAccessingSecurityScopedResource() else {
            self.showAlert(message: "Error accessing the file")
            return
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let modelLoader = ModelLoader()
        do {
            self.sceneView.scene?.rootNode.childNodes.forEach { $0.removeFromParentNode() }
            let scene = try modelLoader.loadModel(from: fileURL)
            for node in scene.rootNode.childNodes {
                self.sceneView.scene?.rootNode.addChildNode(node)
            }
        } catch {
            self.showAlert(message: "Error loading model: \(error.localizedDescription)")
        }
        
        UIView.animate(withDuration: 0.25) {
            self.previewPlaceholderLabel.alpha = 0
        } completion: { _ in
            self.previewPlaceholderLabel.isHidden = true
        }
    }
    
    @objc private func uploadFile() {
        //        resultActivityIndicator.startAnimating()
        //        costActivityIndicator.startAnimating()
        
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
        
        let fullAddress = "http://\(ip):4000/slice"
        
        Task {
            do {
                let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
                try await viewModel.uploadFile(
                    serverAddress: fullAddress,
                    fileURL: fileURL
                )
            } catch {
                await MainActor.run {
                    showAlert(message: error.localizedDescription)
                    //                    resultActivityIndicator.stopAnimating()
                    //                    costActivityIndicator.stopAnimating()
                }
            }
        }
        
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.title = "Calculate print cost"
        
        let materialRow = createInfoRow(title: "Material used:")
        let costRow = createInfoRow(title: "Total cost:")
        infoStack.addArrangedSubview(materialRow)
        infoStack.addArrangedSubview(costRow)
        
        view.addSubview(selectFileButton)
        view.addSubview(uploadButton)
        view.addSubview(infoStack)
        view.addSubview(previewContainer)
        previewContainer.addSubview(sceneView)
        previewContainer.addSubview(previewPlaceholderLabel)
        
        NSLayoutConstraint.activate([
            
            // "Select File" button
            selectFileButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            selectFileButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // "Upload to server" button
            uploadButton.topAnchor.constraint(equalTo: selectFileButton.bottomAnchor, constant: 24),
            uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            infoStack.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 24),
            infoStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            infoStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // 3D-Model preview container
            previewContainer.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 32),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            previewContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            
            // Scene view inside previewContainer
            // *** same as parent ***
            sceneView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            
            previewPlaceholderLabel.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            previewPlaceholderLabel.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor)
            
//            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            loadingIndicator.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 20)
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
        //        resultActivityIndicator.startAnimating()
        //        costActivityIndicator.startAnimating()
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
    
    @objc private func settingsButtonTapped() {
        let controller = SettingsView()
        if let sheetController = controller.sheetPresentationController {
            sheetController.detents = [.medium(), .large()]
        }
        present(controller, animated: true)
    }
    
    //    @objc private func openSheetsView() {
    //        let vc = SheetsView()
    //        self.navigationController?.pushViewController(vc, animated: true)
    //    }
    
    private func updateInfoLabels(material: String, cost: String) {
        guard let materialRow = infoStack.arrangedSubviews[0] as? UIStackView,
              let costRow = infoStack.arrangedSubviews[1] as? UIStackView else { return }
        
        (materialRow.arrangedSubviews[1] as? UILabel)?.text = material
        (costRow.arrangedSubviews[1] as? UILabel)?.text = cost
    }
    
}

extension PrintViewController: IPAddressPickerDelegate {
    func didSelectIPAddress(_ ip: String) {
        self.currentIPAddress = ip
        navigationItem.rightBarButtonItem?.title = ip
    }
}

extension UIView {
    func applyShadow(opacity: Float, radius: CGFloat,
                     offset: CGSize = .zero,
                     color: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.masksToBounds = false
    }
}

extension UIView {
    func updateShadowPath() {
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: layer.cornerRadius
        ).cgPath
    }
}
