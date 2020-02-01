//
//  ViewController.swift
//  TestApp
//
//  Created by Jose Torres on 1/22/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    @IBOutlet weak var sceneView: ARSCNView!
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func addBox(x: Float = 0, y: Float = 0, z: Float = -0.6){
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3(x,y,z)
        
        sceneView.scene.rootNode.addChildNode(boxNode)
        
    }
    
    func addTapGestureToSceneView(){
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addBox()
        addTapGestureToSceneView()
    }
    
    @objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer){
        let tapLoc = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLoc)
        guard let node = hitTestResults.first?.node else {
            let hitTestResultsWithFeatPts = sceneView.hitTest(tapLoc, types: .featurePoint)
            if let hitTestResultsWithFeatPts = hitTestResultsWithFeatPts.first{
                let translation = hitTestResultsWithFeatPts.worldTransform.translation
                addBox(x: translation.x, y: translation.y, z: translation.z)
            }
            return
            
        }
        
        node.removeFromParentNode()
    }
    
}



extension float4x4{
    var translation: float3{
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

