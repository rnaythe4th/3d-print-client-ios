//
//  ModelLoader.swift
//  PrintStoreClient
//
//  Created by May on 5.02.25.
//
import SceneKit
import UIKit

final class ModelLoader {
    func loadModel(from url: URL) throws -> SCNScene {
        // load scene from url
        let scene = try SCNScene(url: url, options: nil)
        // apply color
        for node in scene.rootNode.childNodes {
            applyMaterialColor(UIColor.green, to: node)
        }
        // auto-resize
        let (min, max) = scene.rootNode.boundingBox
        let size = SCNVector3(max.x - min.x, max.y - min.y, max.z - min.z)
        let maxSize = Swift.max(size.x, size.y, size.z)
        let scale = Float(5.0 / maxSize)
        for node in scene.rootNode.childNodes {
            node.scale = SCNVector3(scale, scale, scale)
        }
        
        return scene
    }
    
    // recursive method for applying color
    private func applyMaterialColor(_ color: UIColor, to node: SCNNode) {
        let coloredMaterial = SCNMaterial()
        coloredMaterial.diffuse.contents = color
        
        if let geometry = node.geometry {
            geometry.materials = [coloredMaterial]
        }
        
        // recursive call for child nodes
        for child in node.childNodes {
            applyMaterialColor(color, to: child)
        }
    }
}
