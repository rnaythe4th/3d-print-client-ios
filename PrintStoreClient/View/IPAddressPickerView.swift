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
        textField.placeholder = "Enter new IP address"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
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
        view.backgroundColor = .systemBackground
        title = "Select IP address"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(saveIPAddress)
        )
        setupUI()
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
    
    //    override func viewDidAppear(_ animated: Bool) {
    //        super.viewDidAppear(animated)
    //    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dragAreaView?.removeFromSuperview()
        dragAreaView = nil
    }
    
    private func setupUI() {
        view.addSubview(textField)
        view.addSubview(tableView)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func saveIPAddress() {
        guard let ip = textField.text, !ip.isEmpty else { return }
        ipAddressService.addIPAddress(ip)
        delegate?.didSelectIPAddress(ip)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ipAddressService.recentIPAddresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = ipAddressService.recentIPAddresses[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ip = ipAddressService.recentIPAddresses[indexPath.row]
        delegate?.didSelectIPAddress(ip)
        dismiss(animated: true)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let container = self.navigationController?.view ?? self.view
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            break
        case .changed:
            if translation.y > 0 {
                container?.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled:
            let threshold = view.bounds.height * 0.25
            if translation.y  > threshold || velocity.y > 1000 {
                // calculate animation time remaining
                let remainingDistance = view.bounds.height - translation.y
                let animationDuration = max(0.1, min(0.3, TimeInterval(remainingDistance / velocity.y)))
                UIView.animate(
                    withDuration: animationDuration,
                    delay: 0,
                    options: [.curveEaseOut],
                    animations: {
                        container?.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                    }, completion: {_ in
                        self.dismiss(animated: true, completion: nil)
                    }
                )
            } else {
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    options: [.curveEaseInOut],
                    animations: { container?.transform = .identity },
                    completion: nil
                )
            }
        default:
            break
        }
    }
}

