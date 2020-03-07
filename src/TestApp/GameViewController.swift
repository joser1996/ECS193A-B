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
    var health = 3
    
    @IBOutlet weak var sceneViewGame: ARSCNView!
    @IBOutlet weak var userPrompts: UILabel!
    
    
    func spawnZombie() {
        let angle = Float.random(in: 0 ..< 360)
        let distance = Float.random(in: 1.5 ..< 2)
        let position = (x: distance * cos(angle * Float.pi / 180), y: -0.4, z: distance * sin(angle * Float.pi / 180))
        let zombie = loadCube(position.x, -0.4, position.z, true)
        
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: zombie, requiringSecureCoding: true)
              else { fatalError("can't encode zombie") }
        print("Zombie type: \(type(of: zombie))")
        self.mcService.sendToAllPeers(data)
        
        self.sceneViewGame.scene.rootNode.addChildNode(zombie)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneViewGame.delegate = self
        mcService = previousViewController.mcService
        mcService.receivedDataHandler = receivedData
        
        if isMaster {   // Only master generates game data, sends to slave

            var wave = 1
            var zombieCount = 0
            var timerOne = 5
            var sleep = 7
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if zombieCount == 0 && sleep != 0 {
                    sleep -= 1
                }
                else if zombieCount == 10 + wave * 10 {
                    if sleep == 0 {
                        for _ in 1...(10 + wave * 10) {
                            self.spawnZombie()
                        }
                        wave += 1
                        zombieCount = 0
                        timerOne = 0
                        sleep = 20
                    }
                    else {
                        sleep -= 1
                    }
                }
                else if timerOne == 0 {
                    // Zombie spawn code
                    self.spawnZombie()
                    zombieCount += 1
                    
                    // Reset timer
                    if zombieCount < (10 + wave * 10)/4 {
                        if wave < 3 {
                            timerOne = Int.random(in: 4...6)
                        }
                        else if wave < 5 {
                            timerOne = Int.random(in: 3...5)
                        }
                        else if wave < 10 {
                            timerOne = Int.random(in: 2...4)
                        }
                        else {
                            timerOne = Int.random(in: 1...3)
                        }
                    }
                    else if zombieCount < (10 + wave * 10)/2 {
                        if wave < 5 {
                            timerOne = Int.random(in: 3...5)
                        }
                        else if wave < 10 {
                            timerOne = Int.random(in: 2...4)
                        }
                        else {
                            timerOne = Int.random(in: 1...3)
                        }
                    }
                    else if zombieCount < 3 * (10 + wave * 10)/4 {
                        if wave < 10 {
                            timerOne = Int.random(in: 2...4)
                        }
                        else {
                            timerOne = Int.random(in: 1...3)
                        }
                    }
                    else {
                        timerOne = Int.random(in: 1...3)
                    }
                }
                else {
                    timerOne -= 1
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        let op: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        
        if let worldMap = previousViewController.worldMap {
            configuration.initialWorldMap = worldMap
        }
        
        sceneViewGame.session.run(configuration, options: op)
        sceneViewGame.session.delegate = self
        
        updatePromptLabel(prompt: "Tap on the crosshair")
    }


    func updatePromptLabel( prompt: String) {
        userPrompts.text = prompt
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneViewGame.session.pause()
    }


    @IBAction func pause_button(_ sender: Any) {
        sceneViewGame.session.pause()
             let storyboard = UIStoryboard(name: "Main", bundle: nil)
              let vc = storyboard.instantiateViewController(withIdentifier: "PauseViewController") as! PauseViewController
              self.navigationController!.pushViewController(vc, animated: true)
        //let viewController = PauseViewController(delegate: self)
        //navigationController?.pushViewController(viewController, animated: true)
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
            updatePromptLabel(prompt: "Aim and Tap to shoot cubes!")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.userPrompts.isHidden = true
            }
        }
        
        let hitTestResults = sceneViewGame.hitTest(center)
        let node = hitTestResults.first?.node
        
        if node?.name != "baseNode" {
            node?.removeFromParentNode()
        }
    }
    
    // MARK: - SCNView Delegates
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
        boxNode.name = "baseNode"
        
        if isZombie { boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            
            boxNode.name = "boxNode"
            
            let basePosition = SCNVector3(
                previousViewController.anchorPoint.transform.columns.3.x,
                previousViewController.anchorPoint.transform.columns.3.y,
                previousViewController.anchorPoint.transform.columns.3.z
            )
            let moveAction = SCNAction.move(to: basePosition, duration: 10)
            let deletion = SCNAction.removeFromParentNode()
            let zombieSequence = SCNAction.sequence([moveAction, deletion])
            
            boxNode.runAction(zombieSequence, completionHandler:{
                self.health -= 1
                
                
                print(self.health)
                if (self.health == 0) {
                    print("Game Over\n")
                }
            })
        }
        
        boxNode.position = SCNVector3(x,y,z)
        
        return boxNode
    }
    
    @IBOutlet weak var Heart1: UIImageView!
    @IBOutlet weak var Heart2: UIImageView!
    @IBOutlet weak var Heart3: UIImageView!
}

extension GameViewController : PauseViewControllerDelegate {
    func pauseMenuUnPauseButtonPressed()
    {
        sceneViewGame.session.run(sceneViewGame.session.configuration!)
    }
 }
