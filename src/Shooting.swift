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
        let bullet = SCNSphere(radius: 0.02)
        bullet.firstMaterial?.diffuse.contents = UIColor.red
        let bulletNode = SCNNode(geometry: bullet)
        
        bulletNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        bulletNode.physicsBody?.isAffectedByGravity = false
        
        //do collision bit mask here
        return bulletNode
    }
    
    func fireProjectile(view: ARSCNView) {
        var node = SCNNode()
        node = getBullet()
        let (direction, position) = getUserVector(view: view)
        node.position = position
        
        var nodeDirection = SCNVector3()
        nodeDirection = SCNVector3(direction.x*4, direction.y*4,direction.z*4)
        

        //fire
        node.physicsBody?.applyForce(nodeDirection, asImpulse: true)
        node.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.35), SCNAction.removeFromParentNode()]))
        view.scene.rootNode.addChildNode(node)
        
    }
}
