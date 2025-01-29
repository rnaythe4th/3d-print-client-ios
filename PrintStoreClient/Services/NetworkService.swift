//
//  NetworkService.swift
//  PrintStoreClient
//
//  Created by May on 29.01.25.
//

import Foundation

protocol NetworkServiceProtocol {
    func uploadFile(to serverURL: URL,
                    fileURL: URL,
                    completion: @escaping (Result<PrintResponse, Error>) -> Void)
}

final class NetworkService: NetworkServiceProtocol {
    func uploadFile(to serverURL: URL, fileURL: URL, completion: @escaping (Result<PrintResponse, any Error>) -> Void) {
        
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // add file to request body
        do {
            let fileData = try Data(contentsOf: fileURL)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"uploaded_file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = body
            
            // send request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(NSError(domain: "Response contains no data", code: -1)))
                    return
                }
                // parse JSON
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let materialUsedString = json["materialUsed"] as? String,
                       let materialUsed = Double(materialUsedString) {
                        completion(.success(PrintResponse(materialUsed: materialUsed)))
                    } else {
                        completion(.failure(NSError(domain: "Invalid JSON", code: -2)))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        } catch {
            completion(.failure(error))
            return
        }
    }
}
