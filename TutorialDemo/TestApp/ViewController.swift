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
    //MARK: Properties
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
    

    func addBox(x: Float = 0, y: Float = 0, z: Float = 0, isZombie: Bool){
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        let boxNode = SCNNode()
        boxNode.geometry = box
    
        if isZombie { boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            
            let moveAction = SCNAction.move(to: SCNVector3(0, -0.4, 0), duration: 10)
            
            boxNode.runAction(moveAction)
        }
        
        boxNode.position = SCNVector3(x,y,z)
         sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    func addTapGestureToSceneView(){
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addBox(x: 0, y: 0, z: 0, isZombie: false)
        addTapGestureToSceneView()
        
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            let angle = Float.random(in: 0 ..< 360)
            let distance = Float.random(in: 1.5 ..< 2)
            
            let position = float3(x: distance * cos(angle * Float.pi / 180), y: -0.4, z: distance * sin(angle * Float.pi / 180))
            
            self.addBox(x: position.x, y: -0.4, z: position.z, isZombie: true)
        }
    }
    
    @objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer){
        let tapLoc = recognizer.location(in: sceneView)
        let center = self.view.center
        print(center)
        print(tapLoc)
        let hitTestResults = sceneView.hitTest(center)
        guard let node = hitTestResults.first?.node else {
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

