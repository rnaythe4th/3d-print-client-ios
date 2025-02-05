//
//  PrintError.swift
//  PrintStoreClient
//
//  Created by May on 5.02.25.
//
import Foundation

enum PrintError: LocalizedError {
    case invalidServerAddress
    case fileNotSelected
    case networkError(underlying: Error)
    case parsingError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidServerAddress:
            return "Inavlid server address. Chek it and try again."
        case .fileNotSelected:
            return "File not selected. Please, select a file to upload"
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .parsingError(let underlying):
            return "Error parsing data: \(underlying.localizedDescription)"
        }
    }
}
