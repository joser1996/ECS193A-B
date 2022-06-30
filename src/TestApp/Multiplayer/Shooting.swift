//
//  Shooting.swift
//  TestApp
//
//  Created by Jose Torres on 5/4/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation
import ARKit

class Shooting {
    
    var projectile: String! = "bullet"
    var animation: String! = "normal"
    let modelNames = ModelNameFetcher()
    
    func getUserVector(view: ARSCNView) -> (SCNVector3, SCNVector3) {
        if let frame = view.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform)
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
            return (dir, pos)
        }
        return (SCNVector3(0,0,-1), SCNVector3(0,0,-0.2))
    }
    
    func getBullet() -> SCNNode {
        let modelName = modelNames.getItemModelName(projectile)
        guard let zScene = SCNScene(named: "art.scnassets/\(modelName ?? "bullet.dae")") else {
            fatalError("Couldn't load zombie")
        }
        
        let bulletNode = SCNNode()
        let nodeArray = zScene.rootNode.childNodes
        
        for child in nodeArray {
            bulletNode.addChildNode(child as SCNNode)
        }
        
        bulletNode.name = "bullet"
        bulletNode.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
        let bound = SCNPhysicsShape(geometry: SCNSphere(radius: 0.05), options: [:])
        bulletNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: bound)
        bulletNode.physicsBody?.isAffectedByGravity = false
        
        //do collision bit mask here
        bulletNode.physicsBody?.categoryBitMask = CollisionCategory.bulletCategory.rawValue
        bulletNode.physicsBody?.collisionBitMask = CollisionCategory.targetCategory.rawValue
        
        return bulletNode
    }
    
    func fireProjectile(view: ARSCNView) {
        var node = SCNNode()
        node = getBullet()
        let (direction, position) = getUserVector(view: view)
        node.position = position
        
        var nodeDirection = SCNVector3()
        nodeDirection = SCNVector3(direction.x*6, direction.y*6,direction.z*6)
        
        if animation == "spin" {
            let torqueDirection = SCNVector4(0, 0, 1, 2)
            node.physicsBody?.centerOfMassOffset = SCNVector3(0.03, 0, 0)
            node.physicsBody?.applyTorque(torqueDirection, asImpulse: true)
        }
        
        //fire
        node.physicsBody?.applyForce(nodeDirection, asImpulse: true)
        node.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.35), SCNAction.removeFromParentNode()]))
        view.scene.rootNode.addChildNode(node)
        MusicPlayer.shared.shotSFX()
    }
}



struct CollisionCategory: OptionSet {
    let rawValue: Int
    static let bulletCategory = CollisionCategory(rawValue: 1 << 0)
    static let targetCategory = CollisionCategory(rawValue: 1 << 1)
}
