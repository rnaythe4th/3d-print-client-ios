//
//  IPAddressPickerView.swift
//  PrintStoreClient
//
//  Created by May on 7.02.25.
//
import UIKit

protocol IPAddressPickerDelegate: AnyObject {
    func didSelectIPAddress(_ ip: String)
}

final class IPAddressPickerView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    weak var delegate: IPAddressPickerDelegate?
    private var dragAreaView: UIView?
    private let ipAddressService = IPAddressService()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = .modalElementDynamic
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        textField.placeholder = "Enter new IP address"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        
        button.setTitle("Add", for: .normal)
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            
            config.baseBackgroundColor = .clear
            config.baseForegroundColor = .systemBlue
            config.background.strokeColor = .systemBlue
            config.background.cornerRadius = 8
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
            
            button.configuration = config
        } else {
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemBlue.cgColor
            button.setTitleColor(.systemBlue, for: .normal)
            button.layer.cornerRadius = 8
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        }
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter address first"
        label.textColor = .systemRed
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .modalBackgroundDynamic
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let dragHandleView: UIView = {
        let handle = UIView()
        handle.translatesAutoresizingMaskIntoConstraints = false
        handle.backgroundColor = UIColor.systemGray3
        handle.layer.cornerRadius = 2.5
        return handle
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .modalBackgroundDynamic
        title = "Select IP address"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .done,
            target: self,
            action: #selector(cancelAction)
        )
        setupUI()
        
        // save ip address whe add button is pressed
        addButton.addTarget(self, action: #selector(saveIPAddress), for: .touchUpInside)
        // remove error when user begins to enter symbols in text field
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // keyboard toolbar for dismissing the keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flexibleSpace, doneButton]
        textField.inputAccessoryView = toolbar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navBar = self.navigationController?.navigationBar {
            navBar.transform = CGAffineTransform(translationX: 0, y: 15)
        }
        if let navController = self.navigationController {
            dragAreaView?.removeFromSuperview()
            
            let areaHeight: CGFloat = 60
            let topMargin: CGFloat = 10
            let handleWidth: CGFloat = 40
            let handleHeight: CGFloat = 5
            
            let dragArea = UIView(frame: CGRect(x: 0,
                                                y: 0,
                                                width: navController.view.bounds.width,
                                                height: areaHeight))
            dragArea.backgroundColor = .clear
            dragArea.autoresizingMask = [.flexibleWidth]
            
            dragArea.layer.zPosition = 1000
            
            let handleX = (dragArea.bounds.width - handleWidth) / 2
            let handleY = topMargin
            dragHandleView.frame = CGRect(x: handleX, y: handleY, width: handleWidth, height: handleHeight)
            dragHandleView.layer.cornerRadius = handleHeight / 2
            dragHandleView.clipsToBounds = true
            
            dragArea.addSubview(dragHandleView)
            
            let panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            dragArea.addGestureRecognizer(panGR)
            
            navController.view.addSubview(dragArea)
            navController.view.bringSubviewToFront(dragArea)
            
            self.dragAreaView = dragArea
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dragAreaView?.removeFromSuperview()
        dragAreaView = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func setupUI() {
        view.addSubview(textField)
        view.addSubview(addButton)
        view.addSubview(errorLabel)
        view.addSubview(tableView)
        
        addButton.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        addButton.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NSLayoutConstraint.activate([
            // text field on the left and add button on the right
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -8),
            textField.heightAnchor.constraint(equalToConstant: 36),
            
            // add button on the rigth side after text field
            addButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 34),
            // width is set by intrinsicContentSize
            
            // error label below text field
            errorLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 4),
            errorLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            
            // tableView below error label
            tableView.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func saveIPAddress() {
        guard let ip = textField.text, !ip.trimmingCharacters(in: .whitespaces).isEmpty else {
            // add error styling
            textField.layer.borderWidth = 1.0
            textField.layer.borderColor = UIColor.systemRed.cgColor
            errorLabel.isHidden = false
            return
        }
        
        textField.layer.borderWidth = 0
        textField.layer.borderColor = UIColor.clear.cgColor
        errorLabel.isHidden = true
        
        ipAddressService.addIPAddress(ip)
        delegate?.didSelectIPAddress(ip)
        dismiss(animated: true)
    }
    
    @objc private func textFieldDidChange(_ sender: UITextField) {
        // if text field is not empty then reset the error styling
        if let text = sender.text, !text.trimmingCharacters(in: .whitespaces).isEmpty {
            sender.layer.borderColor = UIColor.clear.cgColor
            sender.layer.borderWidth = 0
            errorLabel.isHidden = true
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ipAddressService.recentIPAddresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = ipAddressService.recentIPAddresses[indexPath.row]
        cell.backgroundColor = .modalElementDynamic
        
        // in case there is only one row, round all edges
        if tableView.numberOfRows(inSection: indexPath.section) == 1 {
            cell.layer.cornerRadius = 8
            cell.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner,
                .layerMinXMaxYCorner
            ]
        }
        // in case it's first row
        else if indexPath.row == 0 {
            cell.layer.cornerRadius = 8
            cell.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner
            ]
        }
        // in case it's the last one
        else if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            cell.layer.cornerRadius = 8
            cell.layer.maskedCorners = [
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
        } else {
            cell.layer.cornerRadius = 0
        }
        
        cell.clipsToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ip = ipAddressService.recentIPAddresses[indexPath.row]
        delegate?.didSelectIPAddress(ip)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // action for delete
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] action, view, completionHandler in
            guard let self = self else {
                completionHandler(false)
                return
            }
            // delete ip from data source
            self.ipAddressService.deleteIPAddress(at: indexPath.row)
            // delete row from tableView
            tableView.deleteRows(at: [indexPath], with: .automatic)
            // update UserDefaults
            completionHandler(true)
        }
        
        // add trash icon
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        // full swipe will call the action
        configuration.performsFirstActionWithFullSwipe = true
        
        return configuration
    }
   
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let modalContainer = self.navigationController?.view ?? self.view
        guard let backgroundView = self.presentingViewController?.view else { return }
        
        let translation = gesture.translation(in: modalContainer)
        let velocity = gesture.velocity(in: modalContainer)
        
        // max distance where progress = 1
        let maxDistance: CGFloat = backgroundView.bounds.height * 0.55
        // define progress
        let progress = min(1, translation.y / maxDistance)
        
        // configure backgroundView
        // !!! MUST BE CHANGED when these values are being changed in Animator  !!!
        let initialScale: CGFloat = 0.92
        let finalScale: CGFloat = 1
        let scale = initialScale + (finalScale - initialScale) * progress
        
        let initialTranslation: CGFloat = 30
        let finalTranslation: CGFloat = 0
        let bgTranslation = initialTranslation + (finalTranslation - initialTranslation) * progress
        
        let backgroundTransform = CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(translationX: 0, y: bgTranslation))
        
        let modalTransform = CGAffineTransform(translationX: 0, y: translation.y)
        
        switch gesture.state {
        case .began:
            break
        case .changed:
            if translation.y > 0 {
                modalContainer?.transform = modalTransform
                backgroundView.transform = backgroundTransform
            }
        case .ended, .cancelled:
            let threshold = (modalContainer?.bounds.height ?? 0) * 0.25
            if translation.y  > threshold || velocity.y > 1000 {
                // calculate animation time remaining
                let containerHeight = modalContainer?.bounds.height ?? 0
                let remainingDistance = containerHeight - translation.y
                let animationDuration = max(0.1, min(0.3, TimeInterval(remainingDistance / abs(velocity.y))))
                UIView.animate(
                    withDuration: animationDuration,
                    delay: 0,
                    options: [.curveEaseOut],
                    animations: {
                        modalContainer?.transform = CGAffineTransform(translationX: 0, y: containerHeight)
                        backgroundView.transform = .identity
                    }, completion: {_ in
                        self.dismiss(animated: false, completion: nil)
                    }
                )
            } else {
                let initialBackgroundTransform = CGAffineTransform(scaleX: initialScale, y: initialScale)
                    .concatenating(CGAffineTransform(translationX: 0, y: initialTranslation))
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    options: [.curveEaseInOut],
                    animations: {
                        modalContainer?.transform = .identity
                        backgroundView.transform = initialBackgroundTransform
                    },
                    completion: nil
                )
            }
        default:
            break
        }
    }
    
    @objc private func cancelAction() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

