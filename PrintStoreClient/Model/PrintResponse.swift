//
//  PrintResponse.swift
//  PrintStoreClient
//
//  Created by May on 29.01.25.
//

import Foundation

struct PrintResponse: Codable {
    let materialUsedString: String
    
    var materialUsed: Double {
        return Double(materialUsedString) ?? 0.0
    }
    
    enum CodingKeys: String, CodingKey {
        case materialUsedString = "materialUsed"
    }
}
