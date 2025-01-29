//
//  PrintViewModel.swift
//  PrintStoreClient
//
//  Created by May on 29.01.25.
//

import UIKit
import Combine

final class PrintViewModel {
    
    @Published var materialUsedText: String? = "Material used: "
    @Published var printCostText: String? = "Print cost: "
    @Published var showAlert: (message: String, isShown: Bool) = ("", false)
    
    private let networkService: NetworkServiceProtocol
    private let materialDensity = 0.00121
    private let moneyPerGram = 0.3
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    // File Upload Function
    func uploadFile(serverAddress: String?, fileURL: URL?) {
        guard let serverAddress = serverAddress,
              let serverURL = URL(string: serverAddress),
              let fileURL = fileURL else {
            showAlert = (message: "Check server address and try again", true)
            return
        }
        
        networkService.uploadFile(to: serverURL, fileURL: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let cost = response.materialUsed * (self?.materialDensity ?? 0) * (self?.moneyPerGram ?? 0)
                    self?.materialUsedText = "Material used: \(response.materialUsed) mm³"
                    self?.printCostText = "Print cost: \(String(format: "%.2f", cost)) BYN"
                case .failure(let error):
                    self?.showAlert = ("Error: \(error.localizedDescription)", true)
                }
            }
        }
    }
    
}
