//
//  SceneFileService.swift
//  PrintStoreClient
//
//  Created by May on 4.02.25.
//
import SceneKit
import UniformTypeIdentifiers

protocol SceneFileServiceProtocol {
    func loadScene(from url: URL) throws -> SCNScene
    func calculateOptimalScale(for scene: SCNScene) -> Float
    func applyDefaultMaterial(to node: SCNNode, color: UIColor)
}

final class SceneFileService: SceneFileServiceProtocol {
    
    func loadScene(from url: URL) throws -> SCNScene {
        do {
            return try SCNScene(url: url, options: nil)
        } catch {
            throw SceneError.loadFailed(error.localizedDescription)
        }
    }
    
    func calculateOptimalScale(for scene: SCNScene) -> Float {
        // auto-scaling
        let (min, max) = scene.rootNode.boundingBox
        let size = SCNVector3(max.x - min.x, max.y - min.y, max.z - min.z)
        let maxSize = Swift.max(size.x, size.y, size.z)
        // set scale
        return Float(5.0 / maxSize)
    }
    
    func applyDefaultMaterial(to node: SCNNode, color: UIColor) {
        let material = SCNMaterial()
        material.diffuse.contents = color
        node.geometry?.materials = [material]
        node.childNodes.forEach { applyDefaultMaterial(to: $0, color: color) }
    }
}

enum SceneError: Error {
    case loadFailed(String)
    case invalidFile
}
