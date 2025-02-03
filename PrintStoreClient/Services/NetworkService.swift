//
//  NetworkService.swift
//  PrintStoreClient
//
//  Created by May on 29.01.25.
//

import Foundation

protocol NetworkServiceProtocol {
    func uploadFile(
        to serverURL: URL,
        fileURL: URL
    ) async throws -> PrintResponse
}

final class NetworkService: NetworkServiceProtocol {
    private let multipartBuilder: MultipartRequestBuilderProtocol
    private let responseParser: ResponseParserProtocol
    private var currentTask: URLSessionTask?
    
    // my first time trying DI
    // Constructor injection, to be precise
    init(
        multipartBuilder: MultipartRequestBuilderProtocol = MultipartRequestBilder(),
        responseParser: ResponseParserProtocol = ResponseParser()
    ) {
        self.multipartBuilder = multipartBuilder
        self.responseParser = responseParser
    }
    
    func uploadFile(to serverURL: URL, fileURL: URL) async throws -> PrintResponse {
        let request = try multipartBuilder.buildRequest(
            serverURL: serverURL,
            fileURL: fileURL
        )
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        return try responseParser.parsePrintResponse(data: data)
    }
    
    func cancel() {
        currentTask?.cancel()
    }
}
