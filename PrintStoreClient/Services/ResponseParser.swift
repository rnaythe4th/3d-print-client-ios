//
//  ResponseParser.swift
//  PrintStoreClient
//
//  Created by May on 4.02.25.
//
import Foundation

enum ResponseParserError: Error {
    case invalidJSON
    case missingField(String)
}

protocol ResponseParserProtocol {
    func parsePrintResponse(data: Data) throws -> PrintResponse
}

final class ResponseParser: ResponseParserProtocol {
    func parsePrintResponse(data: Data) throws -> PrintResponse {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(PrintResponse.self, from: data)
        } catch {
            throw ResponseParserError.invalidJSON
        }
    }
}
