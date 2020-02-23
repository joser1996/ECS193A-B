//
//  ViewController.swift
//  TestApp
//
//  Created by Jose Torres on 1/22/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//
//try passing the config
import UIKit
import ARKit
import MultipeerConnectivity

class GameViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate{
    //MARK: Properties
    var initMap:ARWorldMap!
    // MARK: Multipeer Implementation
    var mcService : MultipeerSession!
    var isMaster: Bool!
    
    var previousViewController: BasePlacementController!
    var didSyncCrosshair = false
    var center = CGPoint(x: 0, y: 0)
    
    @IBOutlet weak var sceneViewGame: ARSCNView!
    
    
    
    override func viewDidLoad() {
        print("In View Did Load")
        super.viewDidLoad()
        sceneViewGame.delegate = self
        mcService = previousViewController.mcService
        mcService.receivedDataHandler = receivedData
        
        if isMaster {   // Only master generates game data, sends to slave
            Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
                let angle = Float.random(in: 0 ..< 360)
                let distance = Float.random(in: 1.5 ..< 2)
                
                let position = (x: distance * cos(angle * Float.pi / 180), y: -0.4, z: distance * sin(angle * Float.pi / 180))
                
                let zombie = self.loadCube(position.x, -0.4, position.z, true)
                
                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: zombie, requiringSecureCoding: true)
                      else { fatalError("can't encode zombie") }
                print("Zombie type: \(type(of: zombie))")
                self.mcService.sendToAllPeers(data)
                
                self.sceneViewGame.scene.rootNode.addChildNode(zombie)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Did appear")
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        let op: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        
        if let worldMap = previousViewController.worldMap {
            configuration.initialWorldMap = worldMap
            print("The map has been set")
        }
        
        sceneViewGame.session.run(configuration, options: op)
        sceneViewGame.session.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneViewGame.session.pause()
    }
    
    //MARK: - AR Session Delegate
    //Inform View of changes in quality of device position tracking
    //code to update in this case goes in this functon
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        // nothing yet
    }
        
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // nothing yet
    }
    
    // Let the View know that the session ended because of some error
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session failed: \(error.localizedDescription)")
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking(nil)
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    //Connect this function to reset button
    func resetTracking(_ sender: UIButton?) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneViewGame.session.run(configuration, options:[.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Session Observer
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Session Interruption is over. Might have to reset tracking and Anchors here
        //resetTracking(nil)
        print("ViewController.sessionInterruptionEnded()")
    }
    
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        
        if !didSyncCrosshair {
            let tapLoc = sender.location(in: sceneViewGame)
            center = tapLoc
            didSyncCrosshair = true
        }
        
        let hitTestResults = sceneViewGame.hitTest(center)
        
        let node = hitTestResults.first?.node
        node?.removeFromParentNode()
    }
    
    // MARK: - SCNView Delegates
    //this function isn't being called
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix("cube") {
            node.addChildNode(loadCube())
        }
    }
    
    var mapProvider: MCPeerID?
    
    // TODO: ADD Functionality to share the World Map data
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        do {
            if let zombie = try NSKeyedUnarchiver.unarchivedObject(ofClass: SCNNode.self, from: data) {
                sceneViewGame.scene.rootNode.addChildNode(zombie)
            }
            else {
                print("unknown data received from \(peer)")
            }
        } catch {
            print("can't zombie data received from \(peer)")
        }
    }
    
    
    // MARK: - AR session management
    private func loadCube(_ x: Float = 0, _ y: Float = 0, _ z: Float = 0, _ isZombie: Bool = false) -> SCNNode {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.name = "boxNode"
        
        if isZombie { boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            
            let moveAction = SCNAction.move(to: SCNVector3(0, -0.4, 0), duration: 10)
            
            boxNode.runAction(moveAction)
        }
        
        boxNode.position = SCNVector3(x,y,z)
        
        return boxNode
    }
    
}

