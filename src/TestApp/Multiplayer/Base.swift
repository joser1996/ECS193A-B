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
    
    
    var health: Int = 3
    var baseNode: SCNNode!
    var anchorPoint: ARAnchor!
    
    func loadBase()  {
        let sceneURL = Bundle.main.url(forResource: "base copy", withExtension: "scn", subdirectory: "art.scnassets")!
        let referenceNode = SCNReferenceNode(url: sceneURL)!
        referenceNode.load()
        referenceNode.name = "baseNode"
            
        self.baseNode =  referenceNode
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
