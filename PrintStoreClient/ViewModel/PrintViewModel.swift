//
//  PrintViewModel.swift
//  PrintStoreClient
//
//  Created by May on 29.01.25.
//

import UIKit
import Combine

final class PrintViewModel {
    
    @Published var state: ViewState = .idle
    
    private let networkService: NetworkServiceProtocol
    private let materialDensity = 0.00121
    private let moneyPerGram = 0.3
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    // File Upload Function
    func uploadFile(serverAddress: String?, fileURL: URL?) async {
        guard let serverAddress = serverAddress,
              let serverURL = URL(string: serverAddress),
              let fileURL = fileURL else {
            self.state = .error(message: "Check server address and try again")
            return
        }
        // uploading file
        state = .loading
        do {
            let response = try await networkService.uploadFile(to: serverURL, fileURL: fileURL)
            
            let cost = response.materialUsed * (self.materialDensity) * (self.moneyPerGram)
            self.state = .success(
                materialUsed: "Material used: \(response.materialUsed) mm³",
                printCost: "Print cost: \(String(format: "%.2f", cost)) BYN")
        } catch {
            self.state = .error(message: "Error: \(error.localizedDescription)")
        }
    }
    
}

enum ViewState {
    case idle // initial state
    case loading
    case success(materialUsed: String, printCost: String)
    case error(message: String)
}
