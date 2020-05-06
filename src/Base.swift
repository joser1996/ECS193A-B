//
//  Base.swift
//  TestApp
//
//  Created by Jose Torres on 5/6/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation
import ARKit
class Base {
    
    var baseNode: SCNNode!
    var anchorPoint: ARAnchor!
    
    func loadBase()  {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.name = "baseNode"
        self.baseNode =  boxNode
    }
    
    func basePlacing(sender: UITapGestureRecognizer, arView: ARSCNView) {
         guard let hitTestResult = arView.hitTest(sender.location(in: arView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane]).first else {return}
         baseNode?.removeFromParentNode()
         
         if self.anchorPoint != nil {
             arView.session.remove(anchor: anchorPoint)
         }
         
         self.anchorPoint = ARAnchor(name: "baseNode", transform: hitTestResult.worldTransform)
         
         arView.session.add(anchor: self.anchorPoint)
     }
    
    
}
