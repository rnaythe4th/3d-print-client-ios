//
//  MultipartRequestBilder.swift
//  PrintStoreClient
//
//  Created by May on 4.02.25.
//
import Foundation

enum MultipartBuilderError: Error {
    case fileReadFailed(Error)
    case invalidFileURL
}

protocol MultipartRequestBuilderProtocol {
    func buildRequest(
        serverURL: URL,
        fileURL: URL
    ) throws -> URLRequest
}

final class MultipartRequestBilder: MultipartRequestBuilderProtocol {
    func buildRequest(
        serverURL: URL,
        fileURL: URL
    ) throws -> URLRequest {
        let boundary = UUID().uuidString
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try buildBody(fileURL: fileURL, boundary: boundary)
        
        return request
    }
    
    private func buildBody(fileURL: URL, boundary: String) throws -> Data {
        var body = Data()
        // add file to request body
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("File not found in: \(fileURL.path)")
                throw MultipartBuilderError.invalidFileURL
            }
            
            let fileData = try Data(contentsOf: fileURL)
            print("File read successfull. Path: \(fileData.count) bytes")
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"uploaded_file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n")
            body.append("Content-Type: application/octet-stream\r\n\r\n")
            body.append(fileData)
            body.append("\r\n")
        } catch {
            print("Error creating request body: \(error.localizedDescription)")
            throw MultipartBuilderError.fileReadFailed(error)
        }
        // finish body
        body.append("--\(boundary)--\r\n")
        
        return body
    }
}

// helper for Data
// originally used .data(using: .utf8)! inside body.append()
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
